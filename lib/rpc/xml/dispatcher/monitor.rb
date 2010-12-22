require 'xmlrpc/client'
require 'openssl'
require 'terminal-table/import'

module Arachni

require Options.instance.dir['lib'] + 'ui/cli/output'

module RPC
module XML
module Dispatcher

#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Monitor

    include Arachni::UI::Output

    def initialize( opts )

        @opts = opts

        debug! if @opts.debug

        # print banner message
        banner

        # if the user needs help, output it and exit
        if opts.help
            usage
            exit 0
        end

        begin
            # start the XMLRPC client
            @dispatcher = ::XMLRPC::Client.new2( @opts.url.to_s )
        rescue Exception => e
            print_error( "Could not connect to server." )
            print_error( "Error: #{e.to_s}." )
            print_debug_backtrace( e )
        end

        # there'll be a HELL of lot of output so things might get..laggy.
        # a big timeout is required to avoid Timeout exceptions...
        @dispatcher.timeout = 9999999


        if @opts.ssl_pkey || @opts.ssl_pkey
            @dispatcher.instance_variable_get( :@http ).
                instance_variable_set( :@ssl_context, prep_ssl_context( ) )
        else
            @dispatcher.instance_variable_get( :@http ).
                instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )
        end

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { exit 0 }
        trap( 'INT' ) { exit 0 }

    end

    def run

        print_line

        # grab the XMLRPC server output while a scan is running
        while( 1 )
            jobs    = @dispatcher.call( 'dispatcher.jobs' )
            running = running_jobs( jobs )
            clear_screen

            banner
            print_job_cnt( running )

            print_line

            print_job_table( running )

            # things will get crazy if we don't block a bit I think...
            # we'll see...
            ::IO::select( nil, nil, nil, 0.5 )
        end

    end

    private

    def print_job_table( jobs )

        headings = [ 'Parent PID', 'PID', 'Port', 'Owner', 'Start time',
            'Current time', 'Run-time', 'Memory', 'Priority', 'State' ]

        rows = []
        jobs.each {
            |job|
            rows << [ job['proc']['ppid'], job['pid'], job['port'], job['owner'],
                job['starttime'].to_time, job['currtime'].to_time,
                secs_to_hms( job['runtime'] ),
                proc_mem( job['proc']['rss'] ), job['proc']['priority'],
                proc_state( job['proc']['state'] ) ]
        }

        return if rows.empty?

        print_line( table( headings, *rows ) )
    end

    def print_job_cnt( jobs )
        print_info( 'Number of running instances: ' + jobs.size.to_s )
    end

    def running_jobs( jobs )
        jobs.reject{ |job| job['proc'].empty? }
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

    def prep_ssl_context

        pkey = ::OpenSSL::PKey::RSA.new( File.read( @opts.ssl_pkey ) )         if @opts.ssl_pkey
        cert = ::OpenSSL::X509::Certificate.new( File.read( @opts.ssl_cert ) ) if @opts.ssl_cert


        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.ca_file = @opts.ssl_ca
        ssl_context.verify_depth = 5
        ssl_context.verify_mode = ::OpenSSL::SSL::VERIFY_PEER |
            ::OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
        ssl_context.key  = pkey
        ssl_context.cert = cert
        return ssl_context
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
        print_line 'Arachni - Web Application Security Scanner Framework
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
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
  Usage:  arachni_xmlrpcd_monitor.rb  [server address]

  Supported options:


    SSL --------------------------

    --ssl_pkey   <file>         location of the SSL private key (.key)

    --ssl_cert   <file>         location of the SSL certificate (.cert)

    --ssl_ca     <file>         location of the CA file (.cert)
USAGE
    end

end

end
end
end
end
