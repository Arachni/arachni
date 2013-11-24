=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class RPC::Server::Framework

#
# Holds methods for slave Instances, both for remote management and utility ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Slave

    #
    # Sets the URL and authentication token required to connect to this
    # Instance's master and makes this Instance a slave.
    #
    # @param    [String]    url     Master's URL in `hostname:port` form.
    # @param    [String]    token   Master's authentication token.
    #
    # @return   [Bool]
    #   `true` on success, `false` if the instance is already part of a
    #   multi-Instance operation.
    #
    # @private
    #
    def set_master( url, token )
        # If we're already a member of a multi-Instance operation bail out.
        return false if !solo?

        # Make sure the desired plugins are loaded before #prepare runs them.
        plugins.load @opts.plugins if @opts.plugins

        # Start the clock and run the plugins.
        prepare

        @master = connect_to_instance( url: url, token: token )

        # Multi-Instance scans need extra info when it comes to auditing,
        # like a whitelist of elements each slave is allowed to audit.
        #
        # Each slave needs to populate a list of element scope-IDs for each page
        # it finds and send it back to the master, which will determine their
        # distribution when it comes time for the audit.
        #
        # This is our buffer for that list.
        @element_ids_per_url = {}

        # Process each page as it is crawled.
        # (The crawl will start the first time any Instance pushes paths to us.)
        spider.on_each_page do |page|
            @status = :crawling

            if page.platforms.any?
                print_info "Identified as: #{page.platforms.to_a.join( ', ' )}"
            end

            # Build a list of deduplicated element scope IDs for this page.
            @element_ids_per_url[page.url] ||= []
            build_elem_list( page ).each do |id|
                @element_ids_per_url[page.url] << id
            end
        end

        # Setup a hook to be called every time we run out of paths.
        spider.after_each_run do
            data = {}

            if @element_ids_per_url.any?
                data[:element_ids_per_url] = @element_ids_per_url.dup
            end

            if spider.done?
                print_status 'Done crawling -- at least for now.'

                data[:platforms]  = Platform::Manager.light if Options.fingerprint?
                data[:crawl_done] = true
            end

            sitrep( data )
            @element_ids_per_url.clear
        end

        # Buffer for logged issues that are to be sent to the master.
        @issue_buffer = []

        # Don't store issues locally -- will still filter duplicate issues though.
        @modules.do_not_store

        # Buffer discovered issues...
        @modules.on_register_results do |issues|
            @issue_buffer |= issues
        end
        # ... and flush it on each page audit.
        on_audit_page do
            sitrep( issues: @issue_buffer.dup )
            @issue_buffer.clear
        end

        print_status "Enslaved by: #{url}"

        true
    end

    # @return   [Bool]  `true` if this instance is a slave, `false` otherwise.
    def slave?
        # If we don't have a connection to the master then we're not a slave.
        !!@master
    end

    private

    # Runs {Framework#audit} and takes care of slave duties like the need to
    # flush out the issue buffer after the audit and let the master know when
    # we're done.
    def slave_run
        audit

        print_status 'Done auditing.'

        sitrep( issues: @issue_buffer.dup, audit_done: true ) do
            @extended_running = false
            @status = :done

            print_info 'Master informed that we\'re done.'
        end

        @issue_buffer.clear
    end

    def sitrep( data, &block )
        block ||= proc{}
        @master.framework.slave_sitrep( data, multi_self_url, master_priv_token, &block )
        nil
    end

    # @return   [String]
    #   Privilege token for the master, we need this in order to report back to it.
    def master_priv_token
        @opts.datastore[:master_priv_token]
    end

end

end
end
