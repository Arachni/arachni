=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'terminal-table/import'
require_relative 'dispatcher_monitor/option_parser'

module Arachni

require Options.paths.lib + 'rpc/client/dispatcher'
require Options.paths.lib + 'utilities'
require_relative '../../utilities'

module UI::CLI
module RPC::Client

# Provides an simplistic Dispatcher monitoring user interface.
#
# @author Tasos "Zapotek" Laskos<tasos.laskos@arachni-scanner.com>
class DispatcherMonitor
    include UI::Output
    include Utilities

    def initialize
        parser = DispatcherMonitor::OptionParser.new
        parser.ssl
        parser.parse

        options = parser.options

        clear_screen
        move_to_home

        begin
            # start the RPC client
            @dispatcher = Arachni::RPC::Client::Dispatcher.new( options, options.dispatcher.url )
            @dispatcher.alive?
        rescue Arachni::RPC::Exceptions::ConnectionError => e
            print_error "Could not connect to Dispatcher at '#{options.url}'."
            print_error "Error: #{e.to_s}."
            print_debug_backtrace e
            exit 1
        end

        trap( 'HUP' ) { exit }
        trap( 'INT' ) { exit }

        run
    end

    private

    def run
        print_line

        loop do
            move_to_home
            stats        = @dispatcher.statistics
            running_jobs = stats['running_jobs']

            print_banner
            print_stats( stats )

            print_line

            print_job_table( running_jobs )

            sleep 1
        end

    end

    def print_job_table( jobs )
        headings = [ 'PID', 'Port', 'Owner', 'Birthdate (Server-side)',
            'Start time (Server-side)', 'Current time (Server-side)', 'Age',
            'Run-time']

        rows = []
        jobs.each do |job|
            rows << [ job['pid'], job['port'], job['owner'],
                job['birthdate'], job['starttime'], job['currtime'],
                seconds_to_hms( job['age'] ), seconds_to_hms( job['runtime'] )]
        end

        return if rows.empty?

        print_line table( headings, *rows )
    end

    def print_stats( stats )
        print_info 'Number of finished instances: ' + stats['finished_jobs'].size.to_s
        print_info 'Number of running instances:  ' + stats['running_jobs'].size.to_s
        print_info 'Initial pool size: ' + stats['init_pool_size'].to_s
        print_info 'Current pool size: ' + stats['curr_pool_size'].to_s
    end

    def proc_mem( rss )
        # we assume a page size of 4096
        (rss.to_i * 4096 / 1024 / 1024).to_s + 'MB'
    end

    def proc_state( state )
        case state
            when 'S'; 'Sleeping'

            when 'D'; 'Disk Sleep'

            when 'Z'; 'Zombie'

            when 'T'; 'Traced/Stoped'

            when 'W'; 'Paging'
        end
    end

    def seconds_to_hms( secs )
        secs = secs.to_i
        [secs/3600, secs/60 % 60, secs % 60].map { |t| t.to_s.rjust( 2, '0' ) }.join(':')
    end

    #
    # Outputs help/usage information.<br/>
    # Displays supported options and parameters.
    #
    def usage
        print_line <<USAGE
  Usage:  #{File.basename( $0 )} host:port

  Supported options:


    SSL --------------------------

    --ssl-pkey=<file>           Location of the SSL private key (.pem)
                                  (Used to verify the the client to the servers.)

    --ssl-cert=<file>           Location of the SSL certificate (.pem)
                                  (Used to verify the the client to the servers.)

    --ssl-ca=<file>             Location of the CA certificate (.pem)
                                  (Used to verify the servers to the client.)


USAGE
    end

end

end
end
end
