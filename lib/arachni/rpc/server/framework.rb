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

require 'tempfile'

module Arachni

lib = Options.dir['lib']
require lib + 'framework'
require lib + 'rpc/server/spider'
require lib + 'rpc/server/module/manager'
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
    require Options.dir['lib'] + 'rpc/server/framework/multi_instance'

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

        #
        # Raised when an option is nor supported for whatever reason.
        #
        # For example, {Options#restrict_paths} isn't supported when in
        # HPG mode.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        #
        class UnsupportedOption < Error
        end
    end

    # Make these inherited methods public again (i.e. accessible over RPC).
    [ :audit_store, :stats, :paused?, :lsmod, :list_modules, :lsplug,
      :list_plugins, :lsrep, :list_reports, :version, :revision, :status,
      :report_as ].each do |m|
        private m
        public  m
    end

    alias :auditstore :audit_store

    def initialize( * )
        super

        # Override standard framework components with their RPC-server counterparts.
        @modules = Module::Manager.new( self )
        @plugins = Plugin::Manager.new( self )
        @spider  = Spider.new( self )
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
    alias :lsplug :list_plugins

    # @return (see Arachni::Framework#list_reports)
    def list_reports
        super.map do |report|
            report[:options] = [report[:options]].flatten.compact.map do |opt|
                opt.to_h.merge( 'type' => opt.type )
            end
            report
        end
    end
    alias :lsrep :list_reports

    # @return   [Bool]
    #   `true` If the system is scanning, `false` if {#run} hasn't been called
    #   yet or if the scan has finished.
    def busy?( &block )
        # If we have a block it means that it was called via RPC, so use the
        # status variable to determine if the scan is done.
        if block_given?
            block.call @prepared && @status != :done
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

        if master? && @opts.restrict_paths.any?
            fail Error::UnsupportedOption,
                 'Option \'restrict_paths\' is not supported when in multi-Instance mode.'
        end

        @extended_running = true

        # Prepare the local instance (runs plugins and starts the timer).
        prepare

        # Start the scan  -- we can't block the RPC server so we're using a Thread.
        Thread.new do
            # If we're in HPG mode (and we're the master) do fancy stuff like
            # distributing and balancing workload as well as starting slave
            # instances and deal with some lower level operations of the local
            # instance like running plug-ins etc.
            if master?
                master_run
            elsif slave?
                slave_run
            else
                audit
                clean_up
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
            block.call false
            return false
        end

        @cleaned_up       = true
        @extended_running = false
        r = super

        if !block_given?
            @status = :done
            return r
        end

        if !has_slaves?
            @status = :done
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
            @status = :done
            block.call true
        end
        map_slaves( foreach, after )
    end

    # Pauses the running scan on a best effort basis.
    def pause( &block )
        r = super
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

    #
    # Merged output of all running instances.
    #
    # This is going to be wildly out of sync and lack A LOT of messages.
    #
    # It's here to give the notion of progress to the end-user rather than
    # provide an accurate depiction of the actual progress.
    #
    # The returned object will be in the form of:
    #
    #   [ { <type> => <message> } ]
    #
    # like:
    #
    #   [
    #       { status: 'Initiating'},
    #       {   info: 'Some informational msg...'},
    #   ]
    #
    # Possible message types are:
    # * `status`  -- Status messages, usually to denote progress.
    # * `info`  -- Informational messages, like notices.
    # * `ok`  -- Denotes a successful operation or a positive result.
    # * `verbose` -- Verbose messages, extra information about whatever.
    # * `bad`  -- Opposite of :ok, an operation didn't go as expected,
    #   something has failed but it's recoverable.
    # * `error`  -- An error has occurred, this is not good.
    # * `line`  -- Generic message, no type.
    #
    # @return   [Array<Hash>]
    #
    # @deprecated
    #
    def output( &block )
        buffer = flush_buffer

        if !has_slaves?
            block.call( buffer )
            return
        end

        foreach = proc do |instance, iter|
            instance.service.output { |out| iter.return( out ) }
        end
        after = proc { |out| block.call( (buffer | out).flatten ) }
        map_slaves( foreach, after )
    end

    # @see Arachni::Framework#stats
    def stats( *args )
        ss = super( *args )
        ss.tap { |s| s[:sitemap_size] = spider.local_sitemap.size } if !solo?
        ss
    end

    #
    # @param    [Integer]   starting_line
    #   Sets the starting line for the range of errors to return.
    #
    # @return   [Array<String>]
    #
    def errors( starting_line = 0, &block )
        return [] if !File.exists? error_logfile

        error_strings = IO.read( error_logfile ).split( "\n" )

        if starting_line != 0
            error_strings = error_strings[starting_line..-1]
        end

        return error_strings if !block_given?

        if !has_slaves?
            block.call( error_strings )
            return
        end

        foreach = proc do |instance, iter|
            instance.framework.errors( starting_line ) { |errs| iter.return( errs ) }
        end
        after = proc { |out| block.call( (error_strings | errs).flatten ) }
        map_slaves( foreach, after )
    end

    #
    # Returns aggregated progress data and helps to limit the amount of calls
    # required in order to get an accurate depiction of a scan's progress and includes:
    #
    # * output messages
    # * discovered issues
    # * overall statistics
    # * overall scan status
    # * statistics of all instances individually
    #
    # @param    [Hash]  opts    Options about what data to include:
    # @option opts [Bool] :messages (true) Output messages.
    # @option opts [Bool] :slaves   (true) Slave statistics.
    # @option opts [Bool] :issues   (true) Issue summaries.
    # @option opts [Bool] :stats   (true) Master/merged statistics.
    # @option opts [Integer] :errors   (false) Logged errors.
    # @option opts [Bool] :as_hash  (false)
    #   If set to `true`, will convert issues to hashes before returning them.
    #
    # @return    [Hash]  Progress data.
    #
    def progress( opts = {}, &block )
        opts = opts.symbolize_keys

        include_stats    = opts[:stats].nil? ? true : opts[:stats]
        include_messages = opts[:messages].nil? ? true : opts[:messages]
        include_slaves   = opts[:slaves].nil? ? true : opts[:slaves]
        include_issues   = opts[:issues].nil? ? true : opts[:issues]
        include_errors   = opts.include?( :errors ) ? (opts[:errors] || 0) : false

        as_hash = opts[:as_hash] ? true : opts[:as_hash]

        data = {
            'stats'  => {},
            'status' => status,
            'busy'   => running?
        }

        data['messages']  = flush_buffer if include_messages

        if include_errors
            data['errors'] = errors( include_errors.is_a?( Integer ) ? include_errors : 0 )
        end

        if include_issues
            data['issues'] = as_hash ? issues_as_hash : issues
        end

        data['instances'] = {} if include_slaves

        stats = []
        stat_hash = {}
        stats( true, true ).each { |k, v| stat_hash[k.to_s] = v } if include_stats

        if master? && include_slaves
            data['instances'][self_url] = stat_hash.dup
            data['instances'][self_url]['url'] = self_url
            data['instances'][self_url]['status'] = status
        end

        stats << stat_hash

        if !has_slaves? || !include_slaves
            if include_stats
                data['stats'] = merge_stats( stats )
            else
                data.delete( 'stats' )
            end
            data['instances'] = data['instances'].values if include_slaves
            block.call( data )
            return
        end

        foreach = proc do |instance, iter|
            instance.framework.progress_data( opts ) do |tmp|
                if !tmp.rpc_exception?
                    tmp['url'] = instance.url
                    iter.return( tmp )
                else
                    iter.return( nil )
                end
            end
        end

        after = proc do |slave_data|
            slave_data.compact!
            slave_data.each do |slave|
                data['messages'] |= slave['messages'] if include_messages
                data['issues']   |= slave['issues'] if include_issues

                if include_errors && slave['errors']
                    data['errors'] ||= []
                    data['errors']  |= slave['errors']
                end

                if include_slaves
                    url = slave['url']
                    data['instances'][url]           = slave['stats'] || {}
                    data['instances'][url]['url']    = url
                    data['instances'][url]['status'] = slave['status']
                end

                stats << slave['stats']
            end

            if include_slaves
                sorted_data_instances = {}
                data['instances'].keys.sort.each do |url|
                    sorted_data_instances[url] = data['instances'][url]
                end
                data['instances'] = sorted_data_instances.values
            end

            if include_stats
                data['stats'] = merge_stats( stats )
            else
                data.delete( 'stats' )
            end

            data['busy']  = slave_data.map { |d| d['busy'] }.include?( true )

            block.call( data )
        end

        map_slaves( foreach, after )
    end
    alias :progress_data :progress

    # @return   [Hash]  Audit results as a {AuditStore#to_h hash}.
    # @see AuditStore#to_h
    def report
        audit_store.to_h
    end
    alias :audit_store_as_hash :report
    alias :auditstore_as_hash :report

    # @return   [String]    YAML representation of {#report}.
    def serialized_report
        report.to_yaml
    end

    # @return   [String]    YAML representation of {#auditstore}.
    def serialized_auditstore
        audit_store.to_yaml
    end

    # @return  [Array<Arachni::Issue>]
    #   First variations of all discovered issues.
    def issues
        auditstore.issues.map { |issue| issue.variations.first || issue }
    end

    # @return   [Array<Hash>]   {#issues} as an array of Hashes.
    # @see #issues
    def issues_as_hash
        issues.map( &:to_h )
    end

    # @return   [String]  URL of this instance.
    # @private
    def self_url
        @self_url ||= "#{@opts.rpc_address}:#{@opts.rpc_port}"
    end

    # @return   [String]  This instance's RPC token.
    def token
        @opts.datastore[:token]
    end

    # @private
    def error_test( str )
        print_error str.to_s
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
