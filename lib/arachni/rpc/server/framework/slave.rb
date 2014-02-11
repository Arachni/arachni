=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class RPC::Server::Framework

# Holds methods for slave Instances.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Slave

    # Sets the URL and authentication token required to connect to this
    # Instance's master and makes this Instance a slave.
    #
    # @param    [String]    url         Master's URL in `hostname:port` form.
    # @param    [Hash]      options
    # @param    [String]    token       Master's authentication token.
    #
    # @return   [Bool]
    #   `true` on success, `false` if the instance is already part of a
    #   multi-Instance operation.
    #
    # @private
    def set_master( url, options = {}, token )
        # If we're already a member of a multi-Instance operation bail out.
        return false if !solo?

        @opts.scope.do_not_crawl

        # Make sure the desired plugins are loaded before #prepare runs them.
        plugins.load @opts.plugins if @opts.plugins

        # Start the clock and run the plugins.
        prepare

        Thread.new { browser_cluster }

        @master = connect_to_instance( url: url, token: token )

        # Buffer for logged issues that are to be sent to the master.
        @issue_buffer = []

        # Don't store issues locally -- will still filter duplicate issues though.
        @checks.do_not_store

        # Buffer discovered issues...
        @checks.on_register_results do |issues|
            @issue_buffer |= issues
        end
        # ... and flush it on each page audit.
        after_page_audit do
            sitrep(
                issues: @issue_buffer.dup,
                browser_cluster_skip_lookup: browser_cluster.skip_lookup_for( browser_job.id ).collection
            )
            @issue_buffer.clear
        end

        print_status "Enslaved by: #{url}"

        true
    end

    def update_browser_cluster_lookup( lookups )
        browser_cluster.update_skip_lookup_for( browser_job.id, lookups )
        nil
    end

    # @return   [Bool]  `true` if this instance is a slave, `false` otherwise.
    def slave?
        # If we don't have a connection to the master then we're not a slave.
        !!@master
    end

    def process_page( page, element_scope_ids, &block )
        Element::Capabilities::Auditable.update_element_restrictions( element_scope_ids )

        if @audit_page_running
            push_to_page_queue page
            return block.call
        end

        block.call

        @audit_page_running = true
        Thread.new do
            audit_page page
            audit

            sitrep( audit_done: true )
            @audit_page_running = false
        end

        nil
    end

    private

    def sitrep( data, &block )
        block ||= proc{}
        @master.framework.slave_sitrep( data, multi_self_url, master_priv_token, &block )
        nil
    end

    # @return   [String]
    #   Privilege token for the master, we need this in order to report back to it.
    def master_priv_token
        @opts.datastore.master_priv_token
    end

end

end
end
