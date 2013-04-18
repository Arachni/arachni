=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
class Framework

#
# Contains utility methods used to connect to instances and dispatchers and
# split and distribute the workload.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Distributor
    include Utilities

    #
    # Maximum concurrency when communicating with instances.
    #
    # Means that you should connect to MAX_CONCURRENCY instances at a time
    # while iterating through them.
    #
    MAX_CONCURRENCY = 20

    #
    # Minimum pages per instance.
    #
    # Prevents slaves from having fewer than MIN_PAGES_PER_INSTANCE pages each,
    # the last slave could of course have less than that if the page count
    # isn't a multiple of MIN_PAGES_PER_INSTANCE.
    #
    MIN_PAGES_PER_INSTANCE = 30

    #
    # Connects to a remote Instance.
    #
    # @param    [Hash]  instance
    #   The hash must hold the `'url'` and the `'token'`. In subsequent calls
    #  the `'token'` can be omitted.
    #
    def connect_to_instance( instance )
        instance = hash_keys_to_sym( instance )

        @tokens  ||= {}
        @tokens[instance[:url]] = instance[:token] if instance[:token]
        Client::Instance.new( @opts, instance[:url], @tokens[instance[:url]] )
    end

    private

    #
    # @param    [Proc]  foreach
    #   Invoked once for each slave instance and an array from the returned values.
    # @param    [Proc]  after  To handle the resulting array.
    #
    def map_slaves( foreach, after )
        wrap = proc do |instance, iterator|
            foreach.call( connect_to_instance( instance ), iterator )
        end
        slave_iterator.map( wrap, after )
    end

    # @param    [Proc]  foreach     Invoked once for each slave instance.
    # @param    [Proc]  after       Invoked after the iteration has completed.
    # @param    [Proc]  block       Invoked once for each slave instance.
    def each_slave( foreach = nil, after = nil, &block )
        foreach ||= block
        wrapped_foreach = proc do |instance, iterator|
            foreach.call( connect_to_instance( instance ), iterator )
        end
        slave_iterator.each( *[wrapped_foreach, after] )
    end

    # @return   <::EM::Iterator>  Iterator for all slave instances.
    def slave_iterator
        iterator_for( @instances )
    end

    #
    # @param    [Array]    arr
    #
    # @return   [::EM::Iterator]  Iterator for the provided array.
    #
    def iterator_for( arr )
        ::EM::Iterator.new( arr, MAX_CONCURRENCY )
    end

    #
    # @param    [Array<Array<String>>]     chunks
    #   Chunks of URLs, each chuck corresponds to each slave.
    # @param    [Hash<String,Array>]     element_ids_per_page
    #   Hash with page urls for keys and arrays of element scope IDs
    #   ({Arachni::Element::Capabilities::Auditable#scope_audit_id}) for
    #   values.
    #
    # @return [Array<Array>]
    #   Unique and evenly distributed elements/chunk for each instance.
    #
    def distribute_elements( chunks, element_ids_per_page )
        #
        # chunks = URLs to be assigned to each instance
        # pages = hash with URLs for key and Pages for values.
        #

        # groups together all the elements of all chunks
        elements_per_chunk = []
        chunks.each_with_index do |chunk, i|
            elements_per_chunk[i] ||= []
            chunk.each do |url|
                elements_per_chunk[i] |= element_ids_per_page[url]
            end
        end

        # removes elements from each chunk
        # that are also included in other chunks too
        #
        # this will leave us with the same grouping as before
        # but without duplicate elements across the chunks,
        # albeit with an non-optimal distribution amongst instances.
        #
        unique_chunks = elements_per_chunk.map.with_index do |chunk, i|
            chunk.reject do |item|
                elements_per_chunk[i..-1].flatten.count( item ) > 1
            end
        end

        # get them into proper order to be ready for proping up
        elements_per_chunk.reverse!
        unique_chunks.reverse!

        # evenly distributed elements across chunks
        # using the previously duplicate elements
        #
        # in order for elements to be moved between chunks they need to
        # have been available in the destination to begin with since
        # we can't assign an element to an instance which won't
        # have a page containing that element
        unique_chunks.each.with_index do |chunk, i|
            chunk.each do |item|
                next_c = unique_chunks[i+1]
                if next_c && (chunk.size > next_c.size ) &&
                    elements_per_chunk[i+1].include?( item )
                    unique_chunks[i].delete( item )
                    next_c << item
                end
            end
        end

        # set them in the same order as the original 'chunks' group
        unique_chunks.reverse
    end

    # @return   [Array<String>]  Scope IDs of all page elements.
    def build_elem_list( page )
        list = []

        scoppe_list = proc { |elems| elems.map { |e| e.scope_audit_id }.uniq }

        list |= scoppe_list.call( page.links  )if @opts.audit_links
        list |= scoppe_list.call( page.forms ) if @opts.audit_forms
        list |= scoppe_list.call( page.cookies ) if @opts.audit_cookies

        list
    end

    # Returns the dispatchers that have different Pipe IDs i.e. can be setup
    # in HPG mode; pretty simple at this point.
    def preferred_dispatchers( &block )
        if !dispatcher
            block.call []
            return
        end

        # keep track of the Pipe IDs we've used
        @used_pipe_ids ||= []

        foreach = proc do |dispatcher, iter|
            connect_to_dispatcher( dispatcher['url'] ).stats do |res|
                if !res.rpc_exception?
                    iter.return( res )
                else
                    iter.return( nil )
                end
            end
        end

        after = proc do |reachable_dispatchers|
            # get the Dispatchers with unique Pipe IDs and send them
            # to the block
            pref_dispatcher_urls = []
            pick_dispatchers( reachable_dispatchers ).each do |dispatcher|
                if !@used_pipe_ids.include?( dispatcher['node']['pipe_id'] )
                    @used_pipe_ids << dispatcher['node']['pipe_id']
                    pref_dispatcher_urls << dispatcher['node']['url']
                end
            end

            block.call( pref_dispatcher_urls )
        end

        # get the info of the local dispatcher since this will be our
        # frame of reference
        dispatcher.node.info do |info|

            # add the Pipe ID of the local Dispatcher in order to avoid it later on
            @used_pipe_ids << info['pipe_id']

            # grab the rest of the Dispatchers of the Grid
            dispatcher.node.neighbours_with_info do |dispatchers|
                # make sure that each Dispatcher is alive before moving on
                iterator_for( dispatchers ).map( foreach, after )
            end
        end
    end

    #
    # Splits URLs into chunks for each instance while taking into account a
    # minimum amount of URLs per instance.
    #
    # @param    [Array<String>]    urls  URL to split into chunks.
    # @param    [Integer]    max_chunks  Maximum amount of chunks, must be > 1.
    #
    # @return   [Array<Array<String>>]   Array of chunks of URLS.
    #
    def split_urls( urls, max_chunks )
        # figure out the min amount of pages per chunk
        min_pages_per_instance = begin
            if @opts.min_pages_per_instance && @opts.min_pages_per_instance.to_i > 0
                @opts.min_pages_per_instance.to_i
            else
                MIN_PAGES_PER_INSTANCE
            end
        rescue
            MIN_PAGES_PER_INSTANCE
        end

        # first try a simplistic approach, just split the the URLs in
        # equally sized chunks for each instance
        orig_chunks = urls.chunk( max_chunks )

        # if the first chunk matches the minimum then they all do
        # (except (possibly) for the last) so return these as is...
        return orig_chunks if orig_chunks[0].size >= min_pages_per_instance

        chunks = []
        idx    = 0
        #
        # otherwise re-arrange the chunks into larger ones
        #
        orig_chunks.each do |chunk|
            chunk.each do |url|
                chunks[idx] ||= []
                if chunks[idx].size < min_pages_per_instance
                    chunks[idx] << url
                else
                    idx += 1
                end
            end
        end
        chunks
    end

    # Picks the dispatchers to use based on their load balancing metrics and
    # the instructed maximum amount of slaves.
    def pick_dispatchers( dispatchers )
        d = dispatchers.sort do |dispatcher_1, dispatcher_2|
            dispatcher_1['node']['score'] <=> dispatcher_2['node']['score']
        end

        begin
            if @opts.max_slaves && @opts.max_slaves.to_i > 0
                d[0...@opts.max_slaves.to_i]
            end
        rescue
            d
        end
    end

    #
    # Spawns, configures and runs a new remote Instance
    #
    # @param    [Hash]      instance_hash   as returned by {Dispatcher#dispatch}
    # @param    [Hash]      auditables
    # @option   auditables    [Array<String>] :urls
    #   URLs to audit -- will be passed as a `restrict_paths` option.
    # @option   auditables    [Array<String>] :elements
    #   Scope IDs of elements to audit.
    # @option   auditables    [Array<String>] :pages
    #   Pages to audit.
    #
    def distribute_and_run( instance_hash, auditables = {}, &block )
        opts = cleaned_up_opts
        opts['restrict_paths'] = auditables[:urls] || []

        %w(exclude include).each do |k|
            opts[k].each.with_index { |v, i| opts[k][i] = v.source }
        end

        opts['pages']    = auditables[:pages] || []
        opts['elements'] = auditables[:elements] || []

        connect_to_instance( instance_hash ).
            service.scan( opts ) do |r|
                @running_slaves << instance_hash[:url]
                block.call( instance_hash ) if block_given?
            end
    end

    def cleaned_up_opts
        opts = @opts.to_h.deep_clone

        (%w(spawns grid grid_mode dir rpc_port rpc_address pipe_id neighbour pool_size) |
            %w(lsmod lsrep rpc_instance_port_range load_profile delta_time) |
            %w(start_datetime finish_datetime)).each do |k|
            opts.delete k
        end

        # Don't let the slaves run plug-ins that are not meant
        # to be distributed.
        opts['plugins'].reject! { |k, _| !@plugins[k].distributable? } if opts['plugins']

        opts['datastore'].delete( :dispatcher_url )
        opts['datastore'].delete( :token )

        opts['datastore']['master_priv_token'] = @local_token

        opts
    end

    def merge_stats( stats )
        final_stats = stats.pop.dup
        return {} if !final_stats || final_stats.empty?

        return final_stats if stats.empty?

        final_stats['current_pages'] = []
        final_stats['current_pages'] << final_stats['current_page'] if final_stats['current_page']

        total = [
            :requests,
            :responses,
            :time_out_count,
            :avg,
            :sitemap_size,
            :auditmap_size,
            :max_concurrency
        ]

        avg = [
            :progress,
            :curr_res_time,
            :curr_res_cnt,
            :curr_avg,
            :average_res_time
        ]

        begin
            stats.each do |instats|
                (avg | total).each do |k|
                    final_stats[k.to_s] += Float( instats[k.to_s] )
                end

                final_stats['current_pages'] << instats['current_page'] if instats['current_page']

                final_stats['eta'] ||= instats['eta']
                final_stats['eta']   = max_eta( final_stats['eta'], instats['eta'] )
            end

            final_stats['sitemap_size'] = final_stats['sitemap_size'].to_i

            avg.each do |k|
                final_stats[k.to_s] /= Float( stats.size + 1 )
                final_stats[k.to_s] = Float( sprintf( "%.2f", final_stats[k.to_s] ) )
            end
        rescue # => e
            # ap e
            # ap e.backtrace
        end

        final_stats
    end

    def max_eta( eta1, eta2 )
        return eta1 if eta1 == eta2

        # splits them into hours, mins and secs
        eta1_splits = eta1.split( ':' )
        eta2_splits = eta2.split( ':' )

        # go through and compare the hours, mins, sec
        eta1_splits.size.times do |i|
            return eta1 if eta1_splits[i].to_i > eta2_splits[i].to_i
            return eta2 if eta1_splits[i].to_i < eta2_splits[i].to_i
        end
    end

    def connect_to_dispatcher( url )
        Client::Dispatcher.new( @opts, url )
    end

    def dispatcher
        return if !@opts.datastore[:dispatcher_url]
        connect_to_dispatcher( @opts.datastore[:dispatcher_url] )
    end

end

end
end
end
end
