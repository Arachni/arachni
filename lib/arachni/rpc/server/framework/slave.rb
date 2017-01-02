=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class RPC::Server::Framework

# Holds methods for slave Instances.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Slave

    # Sets the URL and authentication token required to connect to this
    # Instance's master and makes this Instance a slave.
    #
    # @param    [String]    url
    #   Master's URL in `hostname:port` form.
    # @param    [String]    token
    #   Master's authentication token.
    #
    # @return   [Bool]
    #   `true` on success, `false` if the instance is already part of a
    #   multi-Instance operation.
    #
    # @private
    def set_master( url, token )
        # If we're already a member of a multi-Instance operation bail out.
        return false if !solo?

        options.scope.do_not_crawl

        # Make sure the desired plugins are loaded before #prepare runs them.
        plugins.load options.plugins if options.plugins

        # Start the clock and run the plugins.
        prepare

        Thread.new { browser_cluster }

        @master = connect_to_instance( url: url, token: token )

        # Buffer for logged issues that are to be sent to the master.
        @issue_buffer = []

        # Don't store issues locally -- will still filter duplicate issues though.
        Data.issues.do_not_store

        # Buffer discovered issues...
        Data.issues.on_new do |issue|
            @issue_buffer << issue
        end
        # ... and flush it on each page audit.
        after_page_audit do
            sitrep( issues: @issue_buffer.dup )
            @issue_buffer.clear
        end

        print_status "Enslaved by: #{url}"

        true
    end

    # @return   [Bool]
    #   `true` if this instance is a slave, `false` otherwise.
    def slave?
        # If we don't have a connection to the master then we're not a slave.
        !!@master
    end

    # @param    [Array<Page>]   pages
    #   Pages to audit. If an audit is in progress the pages will be
    #   {#push_to_page_queue pushed to the page queue}, if not the audit
    #   will start right away.
    def process_pages( pages )
        pages.each { |page| push_to_page_queue Page.from_rpc_data( page ), true }

        return if @audit_page_running
        @audit_page_running = true

        # Thread.abort_on_exception = true
        Thread.new do
            exception_jail( false ) { audit }

            sitrep( issues: @issue_buffer.dup, audit_done: true )
            @issue_buffer.clear
            @audit_page_running = false
        end

        nil
    end

    private

    # Here's the reasoning behind this NOP:
    #
    # Slaves should be consumers because the whole idea behind the distribution
    # is that the master splits the available workload as best as possible and
    # a big source of that workload is browser analysis.
    #
    # If slaves perform browser analysis too, then they'd too become producers,
    # but without the capability of distribution, so we'd either have to rectify
    # that by way of a very complex design or have them send all their workload
    # back to the master so that it can distribute it and sync up all Instances'
    # browser states.
    #
    # Either way, we'd end up with high resource utilization from all Instances
    # using their browser cluster full time and from the necessary RPC traffic
    # to have them all reach convergence at key points during the scan.
    #
    # That could allow for faster workload discovery but it would be moot as the
    # bottleneck here is the audit.
    #
    # To cut this short, more workload would be anathema as we'd have no way
    # to actually consume it fast enough and all we'd end up with would be
    # massive resource utilization and a very complex design.
    #
    # To make this a bit more clear, a scan without any checks loaded would
    # end up being faster as it'd purely be a discovery operation, however
    # a full scan would end up taking the same amount time and use massively
    # more resources.
    def slave_perform_browser_analysis( *args )
    end

    def sitrep( data )
        if data[:issues]
            data[:issues] = data[:issues].map(&:to_rpc_data)
            data.delete(:issues) if data[:issues].empty?
        end

        return if data.empty?

        @master.framework.slave_sitrep( data, multi_self_url, master_priv_token ){}
        true
    end

    # @return   [String]
    #   Privilege token for the master, we need this in order to report back to it.
    def master_priv_token
        options.datastore.master_priv_token
    end

end

end
end
