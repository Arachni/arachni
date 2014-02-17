=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class RPC::Server::Framework

# Holds methods for master Instances, both for remote management and utility ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Master

    # Sets this instance as the master.
    #
    # @return   [Bool]
    #   `true` on success, `false` if this instance is not a {#solo? solo} one.
    def set_as_master
        return false if !solo?
        return true if master?

        # Holds info for our slave Instances -- if we have any.
        @slaves      = []

        # Instances which have completed their scan.
        @done_slaves    = Set.new

        # Holds element IDs for each page, to be used as a representation of the
        # the audit workload that will need to be distributed.
        @element_ids_per_url = {}

        @distributed_page_queue = Support::Database::Queue.new

        # Some methods need to be accessible over RPC for instance management,
        # restricting elements, adding more pages etc.
        #
        # However, when in multi-Instance mode, the master should not be tampered
        # with, so we generate a local token (which is not known to regular API clients)
        # to be used server side by self to facilitate access control and only
        # allow slaves to update our runtime data.
        @local_token = Utilities.generate_token

        print_status 'Became master.'

        true
    end

    # @return   [Bool]
    #   `true` if running in HPG (High Performance Grid) mode and instance is
    #   the master, false otherwise.
    def master?
        # Only master needs a local token.
        !!@local_token
    end

    # Enslaves another instance and subsequently becomes the master of the group.
    #
    # @param    [Hash]  instance_info
    #   `{ url: '<host>:<port>', token: 's3cr3t' }`
    #
    # @return   [Bool]
    #   `true` on success, `false` is this instance is a slave (slaves can't
    #   have slaves of their own).
    def enslave( instance_info, &block )
        # Slaves can't have slaves of their own.
        if slave?
            block.call false
            return false
        end

        instance_info = instance_info.symbolize_keys

        fail "Instance info does not contain a 'url' key."   if !instance_info[:url]
        fail "Instance info does not contain a 'token' key." if !instance_info[:token]

        # Since we have slaves we must be a master.
        set_as_master

        # Take charge of the Instance we were given.
        instance = connect_to_instance( instance_info )
        instance.opts.set( prepare_slave_options ) do
            instance.framework.set_master( multi_self_url, token ) do
                @slaves << instance_info

                print_status "Enslaved: #{instance_info[:url]}"

                block.call true if block_given?
            end
        end

        true
    end

    # Signals that a slave has finished auditing -- each slave must call this
    # when it finishes its job.
    #
    # @param    [String]    slave_url   URL of the calling slave.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    def slave_done( slave_url, token = nil )
        return false if master? && !valid_token?( token )
        mark_slave_as_done slave_url

        print_status "Slave done: #{slave_url}"

        cleanup_if_all_done
        true
    end

    # Registers an array holding {Arachni::Issue} objects with the local instance.
    #
    # Used by slaves to register the issues they find.
    #
    # @param    [Array<Arachni::Issue>]    issues
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    def update_issues( issues, token = nil )
        return false if master? && !valid_token?( token )
        @checks.class.register_results( issues )
        true
    end

    # Used by slaves to impart the knowledge they've gained during the scan to
    # the master as well as for signaling.
    #
    # @param    [Hash]     data
    # @option data [Boolean] :crawl_done
    #   `true` if the peer has finished crawling, `false` otherwise.
    # @option data [Boolean] :audit_done
    #   `true` if the slave has finished auditing, `false` otherwise.
    # @option data [Hash] :element_ids_per_url
    #   List of element IDs (as created by
    #   {Arachni::Element::Capabilities::Auditable#audit_scope_id}) for each
    #   page (by URL).
    # @option data [Hash] :platforms
    #   List of platforms (as created by {Platform::Manager.light}).
    # @option data [Array<Arachni::Issue>]    issues
    #
    # @param    [String]    url
    #   URL of the slave.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    def slave_sitrep( data, url, token = nil )
        return false if master? && !valid_token?( token )

        if data[:browser_cluster_skip_lookup]
            browser_cluster.update_skip_lookup_for(
                browser_job.id, data[:browser_cluster_skip_lookup]
            )
        end

        update_issues( data[:issues] || [], token )

        Platform::Manager.update_light( data[:platforms] || {} ) if Options.fingerprint?

        slave_done( url, token ) if data[:audit_done]

        true
    end

    private

    def master_run
        # We need to take our cues from the local framework as some plug-ins may
        # need the system to wait for them to finish before moving on.
        sleep( 0.2 ) while paused?

        # Grid-related operations.
        return master_scan_run if !@opts.dispatcher.grid?

        # Prepare a block to process each Dispatcher and request slave instances
        # from it. If we have any available Dispatchers, that is.
        each = proc do |d_url, iterator|
            d_opts = {
                'rank'   => 'slave',
                'target' => @opts.url,
                'master' => multi_self_url
            }

            print_status "Requesting Instance from Dispatcher: #{d_url}"
            connect_to_dispatcher( d_url ).
                dispatch( multi_self_url, d_opts, false ) do |instance_hash|
                enslave( instance_hash ){ |b| iterator.next }
            end
        end

        # Get slaves from Dispatchers with unique Pipe IDs in order to take
        # advantage of line aggregation if we're in aggregation mode.
        if @opts.dispatcher.grid_aggregate?
            print_info 'In Grid line-aggregation mode, will only request' <<
                        ' Instances from Dispatcher with unique Pipe-IDs.'

            preferred_dispatchers do |pref_dispatchers|
                iterator_for( pref_dispatchers ).each( each, proc { master_scan_run } )
            end

        # If we're not in aggregation mode then we're in load balancing mode
        # and that is handled better by our Dispatcher so ask it for slaves.
        else
            print_info 'In Grid load-balancing mode, letting our Dispatcher' <<
                        ' sort things out.'

            q = Queue.new
            @opts.spawns.times do
                dispatcher.dispatch( multi_self_url ) do |instance_info|
                    enslave( instance_info ){ |b| q << true }
                end
            end

            @opts.spawns.times { q.pop }
            master_scan_run
        end
    end

    def master_scan_run
        initialize_slaves do
            Thread.new do
                # Start the master/local Instance's audit.
                audit

                @finished_auditing = true

                cleanup_if_all_done
            end
        end
    end

    def master_audit_queues
        return if @audit_queues_done == false || !has_audit_workload? ||
            page_limit_reached?

        @audit_queues_done = false

        # If for some reason we've got pages in the page queue this early,
        # consume them and get it over with.
        audit_page_queue

        @first_run = true if @first_run.nil?
        next_page = nil
        while !page_limit_reached? && (page = next_page || pop_page_from_url_queue)
            next_page = nil

            # We don't care about the results, we just want to pass the seed
            # page's elements through the filters to be marked as seen.
            split_page_workload( [page] ) if @first_run
            @first_run = false

            # Distribute workload from the URL queue.
            pages = []
            page_lookahead = calculate_workload_size( @url_queue.size )
            page_lookahead.times do
                pop_page_from_url_queue do |p|
                    pages << p

                    # Push any new resources to the audit queue.
                    push_paths_from_page( p ) if p

                    next if pages.size != page_lookahead

                    distribute_page_workload( pages ) { |np| next_page = np }
                end
            end

            # We're counting on piggybacking the next page retrieval and the
            # workload gathering and distribution with the page audit, however
            # if there wasn't an audit we need to force an HTTP run.
            audit_page( page ) or http.run

            audit_page_queue
        end

        audit_page_queue

        @audit_queues_done = true
        true
    end

    def master_audit_page_queue
        while !page_limit_reached? && (page = pop_page_from_queue)

            # Only distribute the page queue workload if we have idle slaves,
            # the queue isn't going anywhere so there's no rush and we shouldn't
            # risk a situation where a slave gets too much work, leaving other
            # Instances with nothing to do.
            if has_idle_slaves?
                pages = []
                calculate_workload_size( @page_queue.size ).times do
                    pages << @page_queue.pop
                end
                distribute_page_workload( pages )
            end

            audit_page( page )
        end
    end

    def pop_page_from_queue
        if @distributed_page_queue && !@distributed_page_queue.empty?
            return @distributed_page_queue.pop
        end

        super
    end

    def push_to_distributed_page_queue( page )
        return false if skip_page?( page )
        @distributed_page_queue << page
        true
    end

    def clear_distributed_page_queue
        return if !@distributed_page_queue
        @distributed_page_queue.clear
    end

    # Cleans up the system if all Instances have finished.
    def cleanup_if_all_done
        return if !@finished_auditing || !slaves_done?

        clear_filters
        clear_distributed_page_queue

        # We pass a block because we want to perform a grid cleanup, not just a
        # local one.
        clean_up{}
    end

    def has_slaves?
        @slaves && @slaves.any?
    end

end

end
end
