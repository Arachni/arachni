=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'tempfile'

module Arachni

lib = Options.paths.lib
require lib + 'framework'
require lib + 'rpc/server/check/manager'
require lib + 'rpc/server/plugin/manager'

module RPC
class Server

# Wraps the framework of the local instance and the frameworks of all its slaves
# (when it is a Master in multi-Instance mode) into a neat, easy to handle package.
#
# @note Ignore:
#
#   * Inherited methods and attributes -- only public methods of this class are
#       accessible over RPC.
#   * `block` parameters, they are an RPC implementation detail for methods which
#       perform asynchronous operations.
#
# @private
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Framework < ::Arachni::Framework
    require Options.paths.lib + 'rpc/server/framework/multi_instance'

    include Utilities
    include MultiInstance

    # Make inherited methods visible over RPC.
    MultiInstance.public_instance_methods( false ).each do |m|
        private m
        public  m
    end

    # {RPC::Server::Framework} error namespace.
    #
    # All {RPC::Server::Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Framework::Error

        # Raised when an option is nor supported for whatever reason.
        #
        # For example, {OptionGroups::Scope#restrict_paths} isn't supported
        # when in HPG mode.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class UnsupportedOption < Error
        end
    end

    # Make these inherited methods public again (i.e. accessible over RPC).
    [ :statistics, :version, :status, :report_as, :list_platforms, :list_platforms,
      :sitemap ].each do |m|
        private m
        public  m
    end

    def initialize( * )
        super

        # Override standard framework components with their RPC-server counterparts.
        @checks  = Check::Manager.new( self )
        @plugins = Plugin::Manager.new( self )
    end

    # @return   [Report]
    #   {Report#to_rpc_data}
    def report( &block )
        # If a block is given it means the call was form an RPC client.
        if block_given?
            block.call super.to_rpc_data
            return
        end

        super
    end

    # @return (see Arachni::Framework#list_plugins)
    def list_plugins
        super.map do |plugin|
            plugin[:options] = plugin[:options].map(&:to_h)
            plugin
        end
    end

    # @return (see Arachni::Framework#list_reporters)
    def list_reporters
        super.map do |reporter|
            reporter[:options] = reporter[:options].map(&:to_h)
            reporter
        end
    end

    # @return (see Arachni::Framework#list_checks)
    def list_checks
        super.map do |check|
            check[:issue][:severity] = check[:issue][:severity].to_s
            check
        end
    end

    # @return   [Bool]
    #   `true` If the system is scanning, `false` if {#run} hasn't been called
    #   yet or if the scan has finished.
    def busy?( &block )
        # If we have a block it means that it was called via RPC, so use the
        # status variable to determine if the scan is done.
        if block_given?
            block.call @prepared && status != :done
            return
        end

        !!@extended_running
    end

    # @param    [Integer]   from_index
    #   Get sitemap entries after this index.
    #
    # @return   [Hash<String=>Integer>]
    def sitemap_entries( from_index = 0 )
        return {} if sitemap.size <= from_index + 1

        Hash[sitemap.to_a[from_index..-1] || {}]
    end

    # Starts the scan.
    #
    # @return   [Bool]
    #   `false` if already running, `true` otherwise.
    def run
        # Return if we're already running.
        return false if busy?

        @extended_running = true

        # Prepare the local instance (runs plugins and starts the timer).
        prepare

        # Start the scan  -- we can't block the RPC server so we're using a Thread.
        # Thread.abort_on_exception = true
        Thread.new do
            if !solo?
                multi_run
            else
                super
            end
        end

        true
    end

    # If the scan needs to be aborted abruptly this method takes care of any
    # unfinished business (like signaling running plug-ins to finish).
    #
    # Should be called before grabbing the {#report}, especially when running
    # in multi-Instance mode, as it will take care of merging the plug-in results
    # of all instances.
    #
    # You don't need to call this if you've let the scan complete.
    def clean_up( &block )
        if @rpc_cleaned_up
            # Don't shutdown the BrowserCluster here, its termination will be
            # handled by Instance#shutdown.
            block.call false if block_given?
            return false
        end

        @rpc_cleaned_up   = true
        @extended_running = false

        r = super( false )

        if !block_given?
            state.status = :done
            return r
        end

        if !has_slaves?
            state.status = :done
            block.call r
            return
        end

        foreach = proc do |instance, iter|
            instance.framework.clean_up do
                instance.plugins.results do |res|
                    iter.return( !res.rpc_exception? ? res : nil )
                end
            end
        end
        after = proc do |results|
            @plugins.merge_results( results.compact )
            state.status = :done
            block.call true
        end
        map_slaves( foreach, after )
    end

    # @return  [Array<Hash>]
    #   Issues as {Arachni::Issue#to_rpc_data RPC data}.
    #
    # @private
    def issues
        Data.issues.sort.map(&:to_rpc_data)
    end

    # @return   [Array<Hash>]
    #   {#issues} as an array of Hashes.
    #
    # @see #issues
    def issues_as_hash
        Data.issues.sort.map(&:to_h)
    end

    # @return   [String]
    #   URL of this instance.
    #
    # @private
    def self_url
        options.dispatcher.external_address ||= options.rpc.server_address

        @self_url ||= options.dispatcher.external_address ?
            "#{options.dispatcher.external_address }:#{options.rpc.server_port}" :
            options.rpc.server_socket
    end

    # @return   [String]
    #   This instance's RPC token.
    def token
        options.datastore.token
    end

    # @private
    def error_test( str, &block )
        print_error str.to_s
        return block.call if !has_slaves?

        each = proc { |instance, iter| instance.framework.error_test( str ) { iter.next } }
        each_slave( each, &block )
    end

    private

    def prepare
        return if @prepared
        super
        @prepared = true
    end

end

end
end
end
