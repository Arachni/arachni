=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class RPC::Server::Framework

# Contains utility methods used to connect to instances and dispatchers and
# split and distribute the workload.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Distributor

    # Maximum concurrency when communicating with instances.
    #
    # Means that you should connect to MAX_CONCURRENCY instances at a time
    # while iterating through them.
    MAX_CONCURRENCY = 20

    # Connects to a remote Instance.
    #
    # @param    [Hash]  instance
    #   The hash must hold the `'url'` and the `'token'`. In subsequent calls
    #  the `'token'` can be omitted.
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
        iterator_for( @slaves )
    end

    #
    # @param    [Array]    arr
    #
    # @return   [::EM::Iterator]  Iterator for the provided array.
    #
    def iterator_for( arr )
        ::EM::Iterator.new( arr, MAX_CONCURRENCY )
    end

    private

    # @param    [Integer]   maximum
    #   Maximum allowed workload, to be returned in case the calculation (based
    #   on the amount of {#preferred_slaves}) exceeds it.
    #
    # @see #preferred_slaves
    # @see #split_page_workload
    # @see #distribute_page_workload
    def calculate_workload_size( maximum )
        [10 * (preferred_slaves.size + 1), maximum].min
    end

    # @param    [Array<Page>]   pages
    #   Page workload to be {#split_page_workload split} and distributed to
    #   the master (`self`) and the {#preferred_slaves}.
    # @param    [Block] block
    #   Block to be called with the next page for the master (`self`), giving
    #   us a chance to preload it for a smoother audit.
    def distribute_page_workload( pages, &block )
        workloads = split_page_workload( pages.compact )
        return if workloads.empty?

        instances = preferred_slaves

        # Grab our chunk of the pages from the last slot (which could be empty
        # if there's not enough workload), since we've got the added burden of
        # performing browser analysis while the slaves do not...
        self_workload = workloads.delete_at( instances.size ) || []

        # ... and allow us to preload the next page from it...
        block.call self_workload.pop if block_given?

        # ...and just push the rest to be audited ASAP.
        self_workload.each { |page| push_to_distributed_page_queue( page ) }

        # Assign the rest of the workload amongst the slaves.
        workloads.each.with_index do |workload, i|
            # We won't see these pages again so this is our only chance to
            # process them.
            (workload - self_workload).each do |p|
                add_to_sitemap( p )
                # Push any new resources to the audit queue.
                push_paths_from_page( p ) if crawl?
                perform_browser_analysis p
            end

            # Assign the workload to the slave.
            connect_to_instance( instances[i] ).
                framework.process_pages( workload ) do
                    # Slave got workload, remove it from the 'done' list.
                    mark_slave_as_not_done instances[i][:url]
                end
        end
    end

    # @param    [Array<Page>]   pages
    #   Page workload to be split for {#distribute_page_workload distribution}
    #   based on the amount of {#preferred_slaves}.
    #
    # @return   [Array<Array<Page>>]
    #   Chunks of pages (with {#Page#audit_whitelist} configured) for each
    #   instance.
    #
    #   Distribution is per-element and not per-page, that is, the focus is placed
    #   on each chunk having an equal amount of element workload. Thus, if a page
    #   needs to be split up, it will be.
    #
    #   If there are new pages without unseen elements, they will be equally
    #   distributed but their elements will {#Page#do_not_audit_elements not be audited}.
    #   This is because we still need passive checks and browser analysis to
    #   seem them.
    def split_page_workload( pages )
        # Split elements in chunks for each instance and setup audit restrictions
        # for the relevant pages.
        #
        # The pages should contain all their original elements to maintain their
        # integrity, with the elements which should be audited explicitly white-listed.
        workload  = []
        filter_elements_from_pages( pages ).chunk( preferred_slaves.size + 1 ).
            each_with_index do |elements, i|
                workload[i] ||= {}

                elements.each do |element|
                    workload[i][element.page] ||= element.page.dup
                    workload[i][element.page].update_element_audit_whitelist element
                    distributed_pages << element.page
                end

                workload[i] = workload[i].values
            end

        missed_pages = pages.select { |page| !distributed_pages.include? page }

        # Some pages may not have any elements but they still need to be seen in
        # order to be passed to passive checks and be analyzed by the browser
        # cluster.
        missed_pages.chunk( preferred_slaves.size + 1 ).
            each_with_index do |page_chunks, i|
                workload[i] ||= []
                workload[i] |= page_chunks.each(&:do_not_audit_elements)
            end

        workload.reject!(&:empty?)

        #dump_workload_to_console( workload )
        workload
    end

    def dump_workload_to_console( workload )
        find_by_id = proc do |page, id|
            page.elements.find { |e| e.audit_scope_id == id }
        end

        distributed = []
        workload.map do |page_chunks|
            c = page_chunks.map do |p|
                elements = p.audit_whitelist.to_a.map do |id|
                    e = find_by_id.call( p, id )
                    { id => (e.id if e) }
                end

                [p.url, elements]
            end
            distributed << Hash[c]
        end

        ap distributed
    end

    # @return   [Bool]
    #   `true` if all slaves have reported that they've finished their assigned
    #   workload, `false` otherwise.
    def slaves_done?
        synchronize { slave_urls.sort == @done_slaves.to_a.sort }
    end

    # @return   [Bool]
    #   `true` if there are slaves that have finished their assigned workload,
    #   `false` otherwise.
    def has_idle_slaves?
        synchronize { @done_slaves.any? }
    end

    # @param    [String]    url
    #   Slave RPC URL.
    #
    # @return   [Bool]
    #   `true` if the slave has finished its assigned workload, `false` otherwise.
    def slave_done?( url )
        synchronize { @done_slaves.include? url }
    end

    # @param    [String]    url
    #   Slave to mark as done, by RPC URL.
    def mark_slave_as_done( url )
        synchronize { @done_slaves << url }
    end

    # @param    [String]    url
    #   Slave to mark as not done, by RPC URL.
    def mark_slave_as_not_done( url )
        synchronize { @done_slaves.delete url }
    end

    # @return   [Array<String>]
    #   Slave RPC URLs.
    def slave_urls
        @slaves.map { |info| info[:url] }
    end

    # @note Check with {#has_idle_slaves?} first, if you only want to get
    #   slaves which are idle. This method assumes that the workload needs
    #   somewhere to go immediately.
    #
    # @return   [Array<Hash>]
    #   Connection info for the currently {#slave_done? done slaves}.
    #   If all slaves are busy, all are returned.
    def preferred_slaves
        instances = @slaves.select { |info| slave_done? info[:url] }
        instances.any? ? instances : @slaves
    end

    # @param    [Array<Pages>]  pages
    # @return   [Array<Element::Capabilities::Auditable>]
    #   Flat list of all unique and previously un-seen elements from the given
    #   `pages`.
    def filter_elements_from_pages( pages )
        pages.map { |page| build_element_list( page ) }.flatten
    end

    # TODO: Replace this with Page#elements_within_scope to also take
    #   into account all scope restrictions.
    def build_element_list( page )
        [:links, :forms, :cookies, :headers].map do |type|
            filter_elements( page.send(type) ) if @opts.audit.element? type
        end.flatten.compact
    end

    def filter_elements( elements )
        elements.map do |e|
            next if e.inputs.empty?

            id = e.audit_scope_id
            next if distributed_elements.include?( id )
            distributed_elements << id

            e
        end.compact.uniq
    end

    def distributed_elements
        state.rpc.distributed_elements
    end

    def distributed_pages
        state.rpc.distributed_pages
    end

    def clear_filters
        distributed_elements.clear
        distributed_pages.clear
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

    # Picks the dispatchers to use based on their load balancing metrics and
    # the instructed maximum amount of slaves.
    def pick_dispatchers( dispatchers )
        dispatchers = dispatchers.sort_by { |d| d['node']['score'] }
        @opts.spawns > 0 ? dispatchers[0...@opts.spawns] : dispatchers
    end

    # Configures and initializes slave instances.
    #
    # @param    [Block] block
    #   Block to be called once the slaves are ready to receive workload.
    def initialize_slaves( &block )
        slave_options = prepare_slave_options

        [:exclude_path_patterns, :include_path_patterns].each do |k|
            (slave_options[:scope][k] || {}).
                each_with_index { |v, i| slave_options[k][i] = v.source }
        end

        foreach = proc do |slave, iterator|
            slave.service.scan( slave_options ) do
                # Workload will actually be distributed later on so mark it as
                # done by default, i.e. available for work.
                mark_slave_as_done slave.url
                iterator.next
            end
        end

        each_slave( foreach, block )
    end

    # @return   [Hash]
    #   Options suitable to be passed as a configuration to slaves.
    #
    #   Removes options that shouldn't be set like `spawns`, etc.
    #
    #   Finally, it sets the master's privilege token so that the slave can
    #   report back to us.
    def prepare_slave_options
        options = @opts.to_h.deep_clone

        %w(instance rpc dispatcher paths spawns snapshot).each { |k| options.delete k.to_sym }
        options[:http].delete :cookie_jar_filepath

        # Don't let the slaves run plugins that are not meant to be distributed.
        options[:plugins].reject! { |k, _| !@plugins[k].distributable? } if options[:plugins]

        options[:datastore].delete( :dispatcher_url )
        options[:datastore].delete( :token )

        options[:datastore][:master_priv_token] = @local_token

        options
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
        rescue => e
            ap e
            ap e.backtrace
        end

        final_stats['url'] = self_url
        final_stats
    end

    # @param    [String]    eta1    In the form of `hours:minutes:seconds`.
    # @param    [String]    eta2    In the form of `hours:minutes:seconds`.
    #
    # @return   [String]    Returns the longest ETA of the two.
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
        return if !@opts.datastore.dispatcher_url
        connect_to_dispatcher( @opts.datastore.dispatcher_url )
    end

end

end
end
