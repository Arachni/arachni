=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'terminal-table/import'

module Arachni

require Options.dir['lib'] + 'rpc/client/dispatcher'
require Options.dir['lib'] + 'ui/cli/output'
require Options.dir['lib'] + 'ui/cli/utilities'

module UI
class CLI
module RPC

#
# Provides an simplistic Dispatcher monitoring user interface.
#
# @author Tasos "Zapotek" Laskos<tasos.laskos@gmail.com>
#
# @version 0.1.3
#
class DispatcherMonitor
    include Output
    include Utilities

    def initialize( opts = Arachni::Options.instance )
        @opts = opts

        debug if @opts.debug

        clear_screen
        move_to_home

        # print banner message
        print_banner

        # if the user needs help, output it and exit
        if opts.help
            usage
            exit
        end

        if !@opts.url
            print_error 'No server specified.'
            print_line
            usage
            exit
        end

        begin
            # start the RPC client
            @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, @opts.url.to_s )
            @dispatcher.alive?
        rescue RPC::Exceptions::ConnectionError => e
            print_error "Could not connect to server '#{@opts.url}'."
            print_error "Error: #{e.to_s}."
            print_debug_backtrace e
            exit
        end

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { exit }
        trap( 'INT' ) { exit }

        run
    end

    private

    def run
        print_line

        # grab the XMLRPC server output while a scan is running
        loop do
            move_to_home
            stats        = @dispatcher.stats
            running_jobs = stats['running_jobs']

            print_banner
            print_stats( stats )

            print_line

            print_job_table( running_jobs )

            # things will get crazy if we don't block a bit I think...
            # we'll see...
            ::IO::select( nil, nil, nil, 1 )
        end

    end

    def print_job_table( jobs )
        headings = [ 'Parent PID', 'PID', 'Port', 'Owner', 'Birthdate (Server-side)',
            'Start time (Server-side)', 'Current time (Server-side)', 'Age',
            'Run-time', 'Memory', 'Priority', 'State' ]

        rows = []
        jobs.each do |job|
            rows << [ job['proc']['ppid'], job['pid'], job['port'], job['owner'],
                job['birthdate'].to_time, job['starttime'].to_time, job['currtime'].to_time,
                secs_to_hms( job['age'] ), secs_to_hms( job['runtime'] ),
                proc_mem( job['proc']['rss'] ), job['proc']['priority'],
                proc_state( job['proc']['state'] ) ]
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

    def secs_to_hms( secs )
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
end
