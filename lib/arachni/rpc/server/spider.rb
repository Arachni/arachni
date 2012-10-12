=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
class Spider < Arachni::Spider

    private :push, :done?, :sitemap
    public  :push, :done?, :sitemap

    def initialize( framework )
        @opts = framework.opts
        super( @opts )

        @framework = framework

        @peers = {}

        @distribution_filter = BloomFilter.new
    end

    def run( *args, &block )
        @start_time ||= Time.now

        each_peer do |peer|
            peer.spider.update_peers( @peers_array | [self_instance_info] ){}
        end if master? && @peers_array.any?

        #ap 'RUN'
        #ap master?

        on_complete_blocks = @on_complete_blocks.dup
        @on_complete_blocks.clear
        super( *args, &block )
        @on_complete_blocks = on_complete_blocks.dup

        call_poller
    end

    def update_peers( peers )
        @peers_array = peers
        sorted_peers = @peers_array.inject( {} ) do |h, p|
            h[p['url']] = framework.connect_to_instance( p )
            h
        end.sort

        @peers = Hash[sorted_peers]

        @peers[self_instance_info['url']] = framework

        @peers = Hash[@peers.sort]
        true
    end

    def sitemap
        @distributed_sitemap || super
    end

    private

    def call_poller
        return if !master?

        #puts 'DONE!'

        @poller ||= ::EM.add_periodic_timer( 1 ) {
            #puts 'Checking peer statuses.'

            all_done? do |res|
                if res
                    #puts 'All done, collecting sitemaps...'
                    collect_sitemaps do |aggregate_sitemap|
                        @distributed_sitemap = aggregate_sitemap

                        #puts aggregate_sitemap.join( "\n" )
                        #puts "---- Found #{aggregate_sitemap.size} URLs in #{Time.now - @start_time} seconds."
                        call_on_complete_blocks
                        @poller.cancel
                    end
                #else
                #    puts 'Still working...'
                end
            end
        }
    end

    def master?
        framework.master?
    end

    def self_instance_info
        {
            'url'   => framework.self_url,
            'token' => @opts.datastore[:token]
        }
    end

    def collect_sitemaps( &block )
        local_sitemap = sitemap

        if @peers.empty?
            block.call( local_sitemap )
            return
        end

        foreach = proc { |peer, iter| peer.spider.sitemap { |s| iter.return( s ) } }
        after = proc { |sitemap| block.call( (sitemap | local_sitemap).flatten.uniq ) }
        map_peers( foreach, after )
    end

    def all_done?( &block )
        statuses = [ done? ]

        if @peers.empty?
            block.call( statuses.first )
            return
        end

        foreach = proc { |peer, iter| peer.spider.done? { |s| iter.return( s ) } }
        after = proc { |s| block.call( !(statuses | s).flatten.include?( false ) ) }
        map_peers( foreach, after )
    end

    #
    # Distributes the paths to the peers
    #
    # @param    [Array<String]  urls    to distribute
    #
    def distribute( urls )
        urls = dedup( urls )
        return false if urls.empty?

        begin
            routed = {}
            urls.each do |c_url|
                next if distributed? c_url
                (routed[route( c_url )] ||= []) << c_url
                distributed c_url
            end
            routed.each { |peer, r_urls| peer.spider.push( r_urls ){} }
        rescue => e
            ap e
            ap e.backtrace
        end
        true
    end

    def distributed?( url )
        @distribution_filter.include? url
    end

    def distributed( url )
        @distribution_filter << url
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
        ::EM::Iterator.new( @peers.reject{ |url, _| url == self_instance_info['url']}.values,
                            Framework::Distributor::MAX_CONCURRENCY )
    end

    def route( url )
        return if !url || url.empty?
        return framework if @peers.empty?
        return @peers.values.first if @peers.size == 1
        @peers.values[url.bytes.inject( :+ ).modulo( @peers.size )]
    end

    def framework
        @framework
    end

end
end
end
end
