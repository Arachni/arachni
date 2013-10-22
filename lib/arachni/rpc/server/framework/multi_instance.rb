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

require_relative 'distributor'
require_relative 'master'
require_relative 'slave'

module Arachni
class RPC::Server::Framework

#
# Holds multi-Instance methods for the {RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module MultiInstance
    include Distributor
    include Slave
    include Master

    # Make inherited methods appear like they were defined in this module,
    # this makes them visible over RPC.
    [Slave, Master].each do |mod|
        mod.public_instance_methods( false ).each do |m|
            private m
            public  m
        end
    end

    # @return   [Bool]
    #   `true` if this instance is running solo (i.e. not a member of a
    #   multi-Instance operation), `false` otherwise.
    def solo?
        !master? && !slave?
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

    #
    # Restricts the scope of the audit to individual elements.
    #
    # @param    [Array<String>]     elements
    #   List of element IDs (as created by
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id}).
    #
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def restrict_to_elements( elements, token = nil )
        return false if master? && !valid_token?( token )
        Element::Capabilities::Auditable.restrict_to_elements( elements )
        true
    end

    #
    # Updates the page queue with the provided pages.
    #
    # @param    [Array<Arachni::Page>]     pages   List of pages.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    def update_page_queue( pages, token = nil )
        return false if master? && !valid_token?( token )
        [pages].flatten.each { |page| push_to_page_queue( page )}
        true
    end

    def multi_self_url
        @opts.rpc_socket || self_url
    end

    private

    def audit
        @spider.clear_distribution_filter
        clear_elem_ids_filter
        super
    end

    def multi_run
        if master?
            master_run
        elsif slave?
            slave_run
        end
    end

    # @return   [Boolean]
    #   `true` if `token` matches the local privilege token, `false` otherwise.
    def valid_token?( token )
        @local_token == token
    end

end
end
end
