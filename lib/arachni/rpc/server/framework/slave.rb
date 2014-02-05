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

        # Make sure the desired plugins are loaded before #prepare runs them.
        plugins.load @opts.plugins if @opts.plugins

        # Start the clock and run the plugins.
        prepare

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
        install_element_scope_restrictions(
            @opts.datastore.total_instances,
            @opts.datastore.routing_id
        )

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
        @opts.datastore.master_priv_token
    end

end

end
end
