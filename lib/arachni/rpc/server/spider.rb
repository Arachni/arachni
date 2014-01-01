=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni

module RPC
class Server

#
# Extends the regular {Arachni::Spider} with high-performance distributed
# capabilities.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Spider < Arachni::Spider

    # Amount of URLs to buffer before distributing.
    BUFFER_SIZE     = 1000

    # How many times to try and fill the buffer before distributing what's in it.
    FILLUP_ATTEMPTS = 200

    private :push, :done?, :sitemap, :running?
    public  :push, :done?, :sitemap, :running?

    def initialize( framework )
        super( framework.opts )

        @framework    = framework
        @peers        = {}
        @done_signals = Hash.new( true )

        @distribution_filter   = Support::LookUp::Moolb.new

        @after_each_run_blocks = []
        @on_first_run_blocks   = []
    end

    def clear_distribution_filter
        @distribution_filter.clear
    end

    # @param    [Block] block
    #   Block to be called after each URL batch has been consumed.
    def after_each_run( &block )
        @after_each_run_blocks << block
    end

    # @param    [Block] block
    #   Block to be called just before the crawl starts.
    def on_first_run( &block )
        @on_first_run_blocks << block
    end

    # @see Arachgni::Spider#run
    def run( *args )
        @first_run_blocks ||= call_on_first_run

        if !solo?
            on_complete_blocks = @on_complete_blocks.dup
            @on_complete_blocks.clear
        end

        super( *args )

        flush_url_distribution_buffer
        master_done_handler

        if slave?
            call_after_each_run
        end

        if !solo?
            @on_complete_blocks = on_complete_blocks.dup
        end

        sitemap
    end

    #
    # Updates the list of Instances to assist in the crawl.
    #
    # @param    [Array<Hash>]  peers
    #   Array containing Instance info hashes -- with `:url` and `:token`
    #   at least.
    #
    # @param    [Block] block
    #   Block to be called once the update operation has completed.
    #
    def update_peers( peers, &block )
        @peers_array = peers
        sorted_peers = @peers_array.inject( {} ) do |h, p|
            h[p[:url]] = framework.connect_to_instance( p )
            h
        end.sort

        @peers = Hash[sorted_peers]

        @peers[framework.multi_self_url] = framework

        @peers = Hash[@peers.sort]

        @peer_urls    = @peers.keys
        @peer_clients = @peers.values

        if !master?
            block.call if block_given?
            return true
        end

        each = proc do |peer, iter|
            peer.spider.update_peers( @peers_array | [self_instance_info] ) {
                iter.return
            }
        end

        map_peers( each, proc { block.call if block_given? } )

        true
    end

    # @return   [Hash<String, Integer>]
    #   URLs crawled by this Instance, along with their HTTP status codes.
    def local_sitemap
        @sitemap
    end

    # @return   [Array<String>] Crawled URLs.
    def sitemap
        @distributed_sitemap || super
    end

    #
    # Sets a peer crawler's state to finished. Exposed so that peers can signal
    # the master once they're done.
    #
    # @param    [String]    url URL of the finished peer.
    #
    def peer_done( url )
        @done_signals[url] = true
        master_done_handler
        true
    end

    #
    # Signals the `master` Instance that this crawler has finished.
    #
    # @param    [Arachni::RPC::Client::Instance]    master
    #
    def signal_if_done( master )
        return if !done?
        master.spider.peer_done( framework.multi_self_url ){}
    end

    private

    # @return   [RPC::Client::Instance] Peer to handle the given item.
    def route_item_to_client( item )
        @peers[route_item_to_url( item )]
    end

    # @return   [RPC::Client::Instance]
    #   URL of the peer to handle the given item.
    def route_item_to_url( item )
        return peer_urls.first if @peers.size == 1

        peer_urls[item.to_s.persistent_hash.modulo( peer_urls.size )]
    end

    # @return   [Array<String>] Sorted peer URLs.
    def peer_urls
        @peer_urls
    end

    # @return   [Array<Arachni::RPC::Client::Instance>] Sorted peer clients.
    def peer_clients
        @peer_clients
    end

    # Collects sitemaps from all peers.
    #
    # @param    [Block] block Block to be passed the merged sitemap.
    def collect_sitemaps( &block )
        local_sitemap = sitemap

        if !master?
            block.call( local_sitemap )
            return
        end

        foreach = proc { |peer, iter| peer.spider.sitemap { |s| iter.return( s ) } }
        after   = proc do |sitemap|
            block.call( (sitemap | local_sitemap).flatten.uniq.sort )
        end

        map_peers( foreach, after )
    end

    def call_on_first_run
        @on_first_run_blocks.each( &:call )
    end

    def call_after_each_run
        @after_each_run_blocks.each( &:call )
    end

    # @param    [String]    url    URL of the peer to set as not done.
    def peer_not_done( url )
        @done_signals[url] = false
        true
    end

    #
    # Checks whether or not the master and its slaves have finished.
    # If so, it collects the sitemaps and calls `on_complete` callbacks.
    #
    # @return   [Boolean]
    #   `true` if all peers were done and it proceeded to processing the
    #   results, `false` if the crawl is still in progress.
    #
    def master_done_handler
        # Once we realize that we're done for the first time then that's it.
        # Ignore residual signals from slaves to avoid calling the #on_complete
        # callbacks more than once.
        @all_done ||= false
        return if @all_done || !master? || !done? || !slaves_done?

        # Really make sure all slaves are done.
        if_slaves_done do
            @all_done = true

            collect_sitemaps do |aggregate_sitemap|
                @distributed_sitemap = aggregate_sitemap
                call_on_complete_blocks
            end
        end

        true
    end

    # @param  [Block]   block
    #   Block to call if all slaves have finished crawling.
    def if_slaves_done( &block )
        each  = proc { |peer, iter| peer.spider.running? { |b| iter.return !!b } }
        after = proc { |results| block.call if !results.include?( true )}
        map_peers( each, after )
    end

    # @note When checking for slave status also use {#if_slaves_done} to
    #   make sure that there weren't any new paths pushed to the in the interim.
    #
    # @return   [Boolean]
    #   `true` if all slaves have signaled that they've finished, `false`
    #   otherwise.
    def slaves_done?
        !@peers.reject{ |url, _| url == self_instance_info[:url] }.keys.
            map { |peer_url| @done_signals[peer_url] }.include?( false )
    end

    def master?
        framework.master?
    end

    def slave?
        framework.slave?
    end

    def solo?
        framework.solo?
    end

    def self_instance_info
        {
            url:   framework.multi_self_url,
            token: framework.token
        }
    end

    #
    # @note Paths are buffered in order to be pushed in batches for better
    #   bandwidth utilization and to keep RPC calls to a minimum
    #
    # Distributes the paths to the peers.
    #
    # @param    [Array<String>]  urls    URLs to distribute.
    #
    def distribute( urls )
        return false if urls.empty?

        @first_run ||= Support::LookUp::HashSet.new

        @routed          ||= {}
        @buffer_size     ||= 0
        @fillup_attempts ||= 0

        urls.each do |c_url|
            next if distributed? c_url
            @buffer_size += 1
            (@routed[route( c_url )] ||= []) << c_url
            distributed c_url
        end

        return if @buffer_size == 0

        # Remove and push our URLs right way.
        push( @routed.delete( framework ) )

        @fillup_attempts += 1

        return if @buffer_size < BUFFER_SIZE && @fillup_attempts < FILLUP_ATTEMPTS

        # Distribute the buffered outgoing URLs.
        flush_url_distribution_buffer

        true
    end

    # Sends the buffered paths to their assigned peer and empties the buffer.
    def flush_url_distribution_buffer
        @routed ||= {}
        @routed.dup.each do |peer, r_urls|

            if !@first_run.include?( peer.url )
                @first_run << peer.url
                peer_not_done( peer.url )
            end

            peer.spider.push( r_urls ) do |included_new_paths|
                peer_not_done( peer.url ) if included_new_paths
            end
        end

        # Clear the counters and the buffer.
        @fillup_attempts = 0
        @buffer_size     = 0
        @routed.clear
    end

    # @param    [String]    url
    #
    # @return   [Boolean]
    #   `true` if the `url` has already been distributed, `false` otherwise.
    #
    # @see #distributed
    def distributed?( url )
        @distribution_filter.include? url
    end

    # @param    [String]    url URL to set a having been distributed.
    # @see #distributed?
    def distributed( url )
        @distribution_filter << url
    end

    # @param    [String]    url URL to route.
    # @return   [RPC::Client::Instance] Peer to handle the `url`.
    def route( url )
        return if !url || url.empty?
        return framework if @peers.empty?
        route_item_to_client( url )
    end

    def map_peers( foreach, after )
        wrap = proc do |instance, iterator|
            foreach.call( instance, iterator )
        end
        peer_iterator.map( wrap, after )
    end

    def each_peer( &block )
        wrap = proc do |instance, iterator|
            block.call( instance, iterator )
        end
        peer_iterator.each( &wrap )
    end

    def peer_iterator
        ::EM::Iterator.new(
            @peers.reject{ |url, _| url == self_instance_info[:url]}.values,
            Framework::Distributor::MAX_CONCURRENCY
        )
    end

    def framework
        @framework
    end

end
end
end
end
