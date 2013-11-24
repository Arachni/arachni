=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class RPC::Server::Framework

#
# Contains utility methods used to connect to instances and dispatchers and
# split and distribute the workload.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Distributor

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
    MIN_PAGES_PER_INSTANCE = 1

    #
    # Connects to a remote Instance.
    #
    # @param    [Hash]  instance
    #   The hash must hold the `'url'` and the `'token'`. In subsequent calls
    #  the `'token'` can be omitted.
    #
    def connect_to_instance( instance )
        instance = instance.symbolize_keys
        @instance_connections ||= {}

        if @instance_connections[instance[:url]]
            return @instance_connections[instance[:url]]
        end

        @tokens ||= {}
        @tokens[instance[:url]] = instance[:token] if instance[:token]
        @instance_connections[instance[:url]] =
            RPC::Client::Instance.new( @opts, instance[:url], @tokens[instance[:url]] )
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
    # @param    [Array<Array<String>>]     url_chunks
    #   Chunks of URLs, each chuck corresponds to each slave.
    # @param    [Hash<String,Array>]     element_ids_per_page
    #   Hash with page urls for keys and arrays of element
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id scope IDs}
    #   for values.
    #
    # @return [Array<Array>]
    #   Unique and evenly distributed elements/chunk for each instance.
    #
    def distribute_elements( url_chunks, element_ids_per_page )
        # Convert chunks of URLs to chunks of elements for these URLs.
        elements_per_chunk = []
        url_chunks.each_with_index do |chunk, i|
            elements_per_chunk[i] ||= Set.new
            chunk.each do |url|
                elements_per_chunk[i] |= element_ids_per_page[url]
            end
        end

        # Remove elements from each chunk which are also included in other
        # chunks.
        #
        # This will leave us with the same grouping as before but without
        # duplicate elements across the chunks, albeit with an non-optimal
        # distribution.
        unique_elements_per_chunk = elements_per_chunk.map.with_index do |elements, i|
            elements.reject do |element|
                more_than_one_in_sets?( elements_per_chunk[i..-1], element )
            end
        end

        # Get them into proper order to be ready for proping up.
        elements_per_chunk.reverse!
        unique_elements_per_chunk.reverse!

        # Evenly distribute elements across chunks using the previously
        # duplicate elements as possible placements.
        #
        # In order for elements to be moved between chunks they need to have
        # been available in the destination to begin with since we can't assign
        # an element to an instance which won't have a page containing that
        # element.
        unique_elements_per_chunk.each.with_index do |elements, i|
            elements.each do |item|
                next if !(next_c = unique_elements_per_chunk[i+1]) ||
                    next_c.size >= elements.size ||
                    !elements_per_chunk[i+1].include?( item )

                next_c << unique_elements_per_chunk[i].delete( item )
            end
        end

        # Set them in the same order as the original 'chunks' group.
        unique_elements_per_chunk.reverse
    end

    # @return   [Array]
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id Scope IDs}
    #   of all page elements with auditable inputs.
    def build_elem_list( page )
        list = []

        list |= elements_to_ids( page.links )   if @opts.audit_links
        list |= elements_to_ids( page.forms )   if @opts.audit_forms
        list |= elements_to_ids( page.cookies ) if @opts.audit_cookies

        list
    end

    def elements_to_ids( elements )
        # Helps us do some preliminary deduplication on our part to avoid sending
        # over duplicate element IDs.
        @elem_ids_filter ||= Support::LookUp::HashSet.new

        elements.map do |e|
            next if e.inputs.empty?

            id = e.scope_audit_id
            next if @elem_ids_filter.include?( id )
            @elem_ids_filter << id

            id
        end.compact.uniq
    end

    def clear_elem_ids_filter
        @elem_ids_filter.clear if @elem_ids_filter
    end

    # @param    [Block] block
    #   Block to be passed the Dispatchers that have different Pipe IDs -- i.e
    #   can be setup in HPG mode; pretty simple at this point.
    def preferred_dispatchers( &block )
        if !dispatcher
            block.call []
            return
        end

        # To keep track of the Pipe IDs we've used.
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

        # Get the Dispatchers with unique Pipe IDs and pass them to the given block.
        after = proc do |reachable_dispatchers|
            pref_dispatcher_urls = []
            pick_dispatchers( reachable_dispatchers.compact ).each do |dispatcher|
                next if @used_pipe_ids.include?( dispatcher['node']['pipe_id'] )

                @used_pipe_ids       << dispatcher['node']['pipe_id']
                pref_dispatcher_urls << dispatcher['node']['url']
            end

            block.call( pref_dispatcher_urls )
        end

        # Get the info of the local dispatcher since this will be our frame of
        # reference.
        dispatcher.node.info do |info|
            # Add the Pipe ID of the local Dispatcher in order to avoid it later on.
            @used_pipe_ids << info['pipe_id']

            # Grab and process the rest of the Grid Dispatchers.
            dispatcher.node.neighbours_with_info do |dispatchers|
                iterator_for( dispatchers ).map( foreach, after )
            end
        end
    end

    #
    # Splits URLs into chunks for each instance while taking into account a
    # {MIN_PAGES_PER_INSTANCE minimum amount of URLs} per instance.
    #
    # @param    [Array<String>]    urls  URLs to split into chunks.
    # @param    [Integer]    max_chunks  Maximum amount of chunks, must be > 1.
    #
    # @return   [Array<Array<String>>]   Array of chunks of URLS.
    #
    def split_urls( urls, max_chunks )
        # Figure out the min amount of pages per chunk.
        if @opts.min_pages_per_instance > 0
            min_pages_per_instance = @opts.min_pages_per_instance
        else
            min_pages_per_instance = MIN_PAGES_PER_INSTANCE
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
        dispatchers = dispatchers.sort_by { |d| d['node']['score'] }
        @opts.max_slaves > 0 ? dispatchers[0...@opts.max_slaves] : dispatchers
    end

    #
    # Spawns, configures and runs a remote Instance.
    #
    # @param    [Hash]      instance_hash
    #   Instance info as returned by {RPC::Server::Dispatcher#dispatch} --
    #   with `:url` and `:token` at least.
    # @param    [Hash]      auditables
    # @option   auditables    [Array<String>] :urls
    #   URLs to audit -- will be passed as a `restrict_paths` option.
    #
    # @option   auditables    [Array<String>] :elements
    #   {Element::Capabilities::Auditable#scope_audit_id Scope IDs} of
    #   elements to audit.
    #
    # @option   auditables    [Array<Arachni::Page>] :pages
    #   Pages to audit.
    #
    def distribute_and_run( instance_hash, auditables = {}, &block )
        opts = cleaned_up_opts

        opts[:restrict_paths] = auditables[:urls] || []

        opts[:multi] = {
            pages:    auditables[:pages]    || [],
            elements: auditables[:elements] || []
        }

        if Options.fingerprint?
            opts[:multi][:platforms] = Platform::Manager.light
        end

        [:exclude, :include].each do |k|
            opts[k].each.with_index { |v, i| opts[k][i] = v.source }
        end

        connect_to_instance( instance_hash ).service.scan( opts ) do
            @running_slaves << instance_hash[:url]
            block.call( instance_hash ) if block_given?
        end
    end

    # @return   [Hash]
    #   Options suitable to be passed as a configuration to other Instances.
    #
    #   Removes options that shouldn't be set for slaves like `spawns`, etc.
    #
    #   Finally, it sets the master's privilege token so that the slave can
    #   report back to us.
    def cleaned_up_opts
        opts = @opts.to_h.deep_clone.symbolize_keys

        (%w(spawns rpc_socket grid_mode dir rpc_port rpc_external_address
            rpc_address pipe_id neighbour pool_size lsmod lsrep
            rpc_instance_port_range load_profile delta_time start_datetime
            finish_datetime)).each do |k|
            opts.delete k.to_sym
        end

        # Don't let the slaves run plugins that are not meant to be distributed.
        opts[:plugins].reject! { |k, _| !@plugins[k].distributable? } if opts[:plugins]

        opts[:datastore].delete( :dispatcher_url )
        opts[:datastore].delete( :token )

        opts[:datastore][:master_priv_token] = @local_token

        opts
    end

    # @param    [Array<Hash>]   stats   Array of {Framework.stats} to merge.
    #
    # @return   [Hash]
    #   Hash with the values of all passed stats appropriately merged.
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
            :curr_avg,
            :curr_res_cnt,
            :sitemap_size,
            :auditmap_size,
            :max_concurrency
        ]

        avg = [
            :progress,
            :curr_res_time,
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

        final_stats['url'] = self_url
        final_stats
    end

    #
    # @param    [String]    eta1    In the form of `hours:minutes:seconds`.
    # @param    [String]    eta2    In the form of `hours:minutes:seconds`.
    #
    # @return   [String]    Returns the longest ETA of the two.
    #
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
        @dispatcher_connections ||= {}
        @dispatcher_connections[url] ||= RPC::Client::Dispatcher.new( @opts, url )
    end

    def dispatcher
        return if !@opts.datastore[:dispatcher_url]
        connect_to_dispatcher( @opts.datastore[:dispatcher_url] )
    end

    def more_than_one_in_sets?( sets, item )
        occurrences = 0
        sets.each do |set|
            occurrences += 1 if set.include?( item )
            return true if occurrences > 1
        end
        false
    end

end

end
end
