require 'terminal-table/import'

module Arachni

require Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Options.instance.dir['lib'] + 'ui/cli/output'

module UI

#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class DispatcherMonitor

    include Arachni::UI::Output

    def initialize( opts )

        @opts = opts

        debug if @opts.debug

        # print banner message
        banner

        # if the user needs help, output it and exit
        if opts.help
            usage
            exit 0
        end

        if !@opts.url
            print_error "No server specified."
            print_line
            usage
            exit 0
        end

        begin
            # start the RPC client
            @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, @opts.url.to_s )
        rescue Exception => e
            print_error( "Could not connect to server." )
            print_error( "Error: #{e.to_s}." )
            print_debug_backtrace( e )
            exit 0
        end

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { exit 0 }
        trap( 'INT' ) { exit 0 }

    end

    def run

        print_line

        # grab the XMLRPC server output while a scan is running
        while( 1 )
            stats        = @dispatcher.stats
            running_jobs = stats['running_jobs']
            clear_screen

            banner
            print_stats( stats )

            print_line

            print_job_table( running_jobs )

            # things will get crazy if we don't block a bit I think...
            # we'll see...
            ::IO::select( nil, nil, nil, 1 )
        end

    end

    private

    def print_job_table( jobs )

        headings = [ 'Parent PID', 'PID', 'Port', 'Owner', 'Birthdate (Server-side)',
            'Start time (Server-side)', 'Current time (Server-side)', 'Age',
            'Run-time', 'Memory', 'Priority', 'State' ]

        rows = []
        jobs.each {
            |job|
            rows << [ job['proc']['ppid'], job['pid'], job['port'], job['owner'],
                job['birthdate'].to_time, job['starttime'].to_time, job['currtime'].to_time,
                secs_to_hms( job['age'] ), secs_to_hms( job['runtime'] ),
                proc_mem( job['proc']['rss'] ), job['proc']['priority'],
                proc_state( job['proc']['state'] ) ]
        }

        return if rows.empty?

        print_line( table( headings, *rows ) )
    end

    def print_stats( stats )
        print_info( 'Number of finished instances: ' + stats['finished_jobs'].size.to_s )
        print_info( 'Number of running instances:  ' + stats['running_jobs'].size.to_s )
        print_info( 'Initial pool size: ' + stats['init_pool_size'].to_s )
        print_info( 'Current pool size: ' + stats['curr_pool_size'].to_s )
    end

    def clear_screen
        puts "\e[H\e[2J"
    end

    def proc_mem( rss )
        # we assume a page size of 4096
        (rss.to_i * 4096 / 1024 / 1024).to_s + 'MB'
    end

    def proc_state( state )
        case state
            when 'S'
            return 'Sleeping'

            when 'D'
            return 'Disk Sleep'

            when 'Z'
            return 'Zombie'

            when 'T'
            return 'Traced/Stoped'

            when 'W'
            return 'Paging'
        end
    end

    def secs_to_hms( secs )
        secs = secs.to_i
        return [secs/3600, secs/60 % 60, secs % 60].map {
            |t|
            t.to_s.rjust( 2, '0' )
        }.join(':')
    end


    #
    # Outputs Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    # @see VERSION
    # @see REVISION
    #
    # @return [void]
    #
    def banner
        print_line BANNER
        print_line
        print_line
    end

    #
    # Outputs help/usage information.<br/>
    # Displays supported options and parameters.
    #
    # @return [void]
    #
    def usage
        print_line <<USAGE
  Usage:  arachni_rpcd_monitor  host:port

  Supported options:


    SSL --------------------------

    --ssl-pkey   <file>         location of the SSL private key (.pem)
                                    (Used to verify the the client to the servers.)

    --ssl-cert   <file>         location of the SSL certificate (.pem)
                                    (Used to verify the the client to the servers.)

    --ssl-ca     <file>         location of the CA certificate (.pem)
                                    (Used to verify the servers to the client.)
USAGE
    end

end

end
end
