=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'distributor'
require_relative 'master'
require_relative 'slave'

module Arachni
class RPC::Server::Framework

# Holds multi-Instance methods for the {RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

    # @param    [Integer]   starting_line
    #   Sets the starting line for the range of errors to return.
    #
    # @return   [Array<String>]
    def errors( starting_line = 0, &block )
        return [] if !File.exists? error_logfile

        error_strings = error_buffer.dup

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

    # Provides aggregated progress data.
    #
    # @param    [Hash]  opts
    #   Options about what data to include:
    # @option opts [Bool] :slaves   (true)
    #   Slave statistics.
    # @option opts [Bool] :issues   (true)
    #   Issue summaries.
    # @option opts [Bool] :statistics   (true)
    #   Master/merged statistics.
    # @option opts [Bool, Integer] :errors   (false)
    #   Logged errors. If an integer is provided it will return errors past that
    #   index.
    # @option opts [Bool, Integer] :sitemap   (false)
    #   Scan sitemap. If an integer is provided it will return entries past that
    #   index.
    # @option opts [Bool] :as_hash  (false)
    #   If set to `true`, will convert issues to hashes before returning them.
    #
    # @return    [Hash]
    #   Progress data.
    def progress( opts = {}, &block )
        opts = opts.my_symbolize_keys

        include_statistics = opts[:statistics].nil? ? true : opts[:statistics]
        include_slaves     = opts[:slaves].nil?     ? true : opts[:slaves]
        include_issues     = opts[:issues].nil?     ? true : opts[:issues]
        include_sitemap    = opts.include?( :sitemap ) ?
            (opts[:sitemap] || 0) : false
        include_errors     = opts.include?( :errors ) ?
            (opts[:errors] || 0) : false

        as_hash = opts[:as_hash] ? true : opts[:as_hash]

        data = {
            status: status,
            busy:   running?,
            seed:   Utilities.random_seed
        }

        if include_issues
            data[:issues] = as_hash ? issues_as_hash : issues
        end

        if include_statistics
            data[:statistics] = self.statistics
        end

        if include_sitemap
            data[:sitemap] =
                sitemap_entries( include_sitemap.is_a?( Integer ) ? include_sitemap : 0 )
        end

        if include_errors
            data[:errors] =
                errors( include_errors.is_a?( Integer ) ? include_errors : 0 )
        end

        if solo? || slave? || !include_slaves
            block.call data.merge( messages: status_messages )
            return
        end

        data[:instances] = {
            self_url => {
                url:      self_url,
                status:   status,
                messages: status_messages,
                busy:     running?
            }
        }

        if include_statistics
            data[:instances][self_url][:statistics] = data[:statistics].dup
        end

        foreach = proc do |instance, iter|
            instance.framework.progress( opts.merge( issues: false ) ) do |d|
                if d.rpc_exception?
                    iter.return( nil )
                else
                    iter.return( d.merge( url: instance.url ) )
                end
            end
        end

        after = proc do |slave_data|
            slave_data.compact!

            slave_data.each do |slave|
                slave = slave.my_symbolize_keys

                if include_errors
                    data[:errors] |= slave[:errors]
                end

                data[:instances][slave[:url]] = slave
            end

            data[:instances] = Hash[data[:instances].sort_by { |k, _| k }].values

            if include_statistics
                data[:statistics] =
                    merge_statistics( data[:instances].map { |v| v[:statistics] } )
            end

            data[:busy]   = slave_data.map { |d| d[:busy] }.include?( true )
            data[:master] = self_url

            block.call( data )
        end

        map_slaves( foreach, after )
    end

    # Updates the page queue with the provided pages.
    #
    # @param    [Array<Arachni::Page>]     pages
    #   List of pages.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]
    #   `true` on success, `false` on invalid `token`.
    def update_page_queue( pages, token = nil )
        return false if master? && !valid_token?( token )
        [pages].flatten.each { |page| push_to_page_queue( page )}
        true
    end

    def multi_self_url
        options.rpc.server_socket || self_url
    end

    private

    def perform_browser_analysis( *args )
        return slave_perform_browser_analysis( *args ) if slave?
        super
    end

    def multi_run
        if master?
            master_run
        elsif slave?
            # NOP
        end
    end

    def audit_queues
        if master?
            master_audit_queues
        else
            super
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
