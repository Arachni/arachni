=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'tempfile'

module Arachni

lib = Options.paths.lib
require lib + 'framework'
require lib + 'rpc/server/check/manager'
require lib + 'rpc/server/plugin/manager'

module RPC
class Server

#
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
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Framework < ::Arachni::Framework
    require Options.paths.lib + 'rpc/server/framework/multi_instance'

    include Utilities
    include MultiInstance

    # Make inherited methods visible over RPC.
    MultiInstance.public_instance_methods( false ).each do |m|
        private m
        public  m
    end

    #
    # {RPC::Server::Framework} error namespace.
    #
    # All {RPC::Server::Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Framework::Error

        # Raised when an option is nor supported for whatever reason.
        #
        # For example, {OptionGroups::Scope#restrict_paths} isn't supported
        # when in HPG mode.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class UnsupportedOption < Error
        end
    end

    # Make these inherited methods public again (i.e. accessible over RPC).
    [ :audit_store, :stats, :paused?, :list_checks, :list_checks, :list_plugins,
      :list_plugins, :list_reports, :list_reports, :version, :status, :report_as,
      :list_platforms, :list_platforms ].each do |m|
        private m
        public  m
    end

    alias :auditstore :audit_store

    def initialize( * )
        super

        # Override standard framework components with their RPC-server counterparts.
        @checks  = Check::Manager.new( self )
        @plugins = Plugin::Manager.new( self )
    end

    # @return (see Arachni::Framework#list_plugins)
    def list_plugins
        super.map do |plugin|
            plugin[:options] = [plugin[:options]].flatten.compact.map do |opt|
                opt.to_h.merge( 'type' => opt.type )
            end
            plugin
        end
    end

    # @return (see Arachni::Framework#list_reports)
    def list_reports
        super.map do |report|
            report[:options] = [report[:options]].flatten.compact.map do |opt|
                opt.to_h.merge( 'type' => opt.type )
            end
            report
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

    #
    # Starts the scan.
    #
    # @return   [Bool]  `false` if already running, `true` otherwise.
    #
    def run
        # Return if we're already running.
        return false if busy?

        @extended_running = true

        # Prepare the local instance (runs plugins and starts the timer).
        prepare

        # Start the scan  -- we can't block the RPC server so we're using a Thread.
        Thread.abort_on_exception = true
        Thread.new do
            if !solo?
                multi_run
            else
                super
            end
        end

        true
    end

    #
    # If the scan needs to be aborted abruptly this method takes care of any
    # unfinished business (like signaling running plug-ins to finish).
    #
    # Should be called before grabbing the {#auditstore}, especially when
    # running in HPG mode as it will take care of merging the plug-in results
    # of all instances.
    #
    # You don't need to call this if you've let the scan complete.
    #
    def clean_up( &block )
        if @cleaned_up
            # Don't shutdown the BrowserCluster here, its termination will be
            # handled by Instance#shutdown.
            block.call false if block_given?
            return false
        end

        @cleaned_up       = true
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

    # Pauses the running scan on a best effort basis.
    def pause( &block )
        # Send the pause request but don't block.
        r = super( false )
        return r if !block_given?

        if !has_slaves?
            block.call true
            return
        end

        each = proc { |instance, iter| instance.framework.pause { iter.next } }
        each_slave( each, proc { block.call true } )
    end

    # Resumes a paused scan right away.
    def resume( &block )
        r = super
        return r if !block_given?

        if !has_slaves?
            block.call true
            return
        end

        each = proc { |instance, iter| instance.framework.resume { iter.next } }
        each_slave( each, proc { block.call true } )
    end

    # @return   [Hash]  Audit results as a {AuditStore#to_h hash}.
    # @see AuditStore#to_h
    def report
        audit_store.to_h
    end
    alias :audit_store_as_hash :report
    alias :auditstore_as_hash :report

    # @return  [Array<Arachni::Issue>]
    #   First variations of all discovered issues with generic info filled in
    #   from the parent.
    def issues
        Data.issues.map { |issue| issue.variations.first.to_solo issue }
    end

    # @return   [Array<Hash>]   {#issues} as an array of Hashes.
    # @see #issues
    def issues_as_hash
        issues.map( &:to_h )
    end

    # @return   [String]  URL of this instance.
    # @private
    def self_url
        @opts.dispatcher.external_address ||= @opts.rpc.server_address

        @self_url ||= @opts.dispatcher.external_address ?
            "#{@opts.dispatcher.external_address }:#{@opts.rpc.server_port}" : @opts.rpc.server_socket
    end

    # @return   [String]  This instance's RPC token.
    def token
        @opts.datastore.token
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
