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

require 'highline/system_extensions'

module Arachni

require Options.dir['mixins'] + 'terminal'
require Options.dir['mixins'] + 'progress_bar'

require Options.dir['lib'] + 'rpc/client/dispatcher'
require Options.dir['lib'] + 'rpc/client/instance'

require Options.dir['lib'] + 'utilities'
require Options.dir['lib'] + 'ui/cli/utilities'
require Options.dir['lib'] + 'framework'

module UI
class CLI

#
# Provides a command-line RPC client and uses a Dispatcher to provide an Instance
# in order to perform a scan.
#
# This interface should be your first stop when looking into using/creating your own
# RPC client.
#
# Of course, you don't need to have access to the framework or any other Arachni
# class for your own client, this is used here just to provide some other info
# to the user.
#
# However, in contrast with everywhere else in the system (where RPC operations
# are asynchronous), this interface operates in blocking mode as its simplicity
# does not warrant the extra complexity of asynchronous calls.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class RPC
    include Arachni::UI::Output
    include CLI::Utilities

    include Arachni::Mixins::Terminal
    include Arachni::Mixins::ProgressBar

    attr_reader :error_log_file

    def initialize( opts )
        @opts = opts

        clear_screen
        move_to_home

        print_banner

        # If we have a profile option load it and merge it with the user
        # supplied options.
        load_profile( @opts.load_profile ) if @opts.load_profile

        debug if @opts.debug

        # We don't need the framework for much, in this case only for report
        # generation, version number etc.
        @framework = Arachni::Framework.new( @opts )

        # If the user needs help, output it and exit.
        if opts.help
            usage
            exit 0
        end

        # Check for missing Dispatcher
        if !@opts.server
            print_error 'Missing server argument.'
            exit 1
        end

        # If the user wants to see the available reports, output them and exit.
        if !opts.lsrep.empty?
            lsrep @framework.lsrep
            exit
        end

        if opts.show_profile
            print_profile
            exit 0
        end

        if opts.save_profile
            exception_jail{ save_profile( opts.save_profile ) }
            exit 0
        end

        begin
            @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, @opts.server )

            # Get a new instance and assign the url we're going to audit as the 'owner'.
            @instance_info = @dispatcher.dispatch( @opts.url )
        rescue Arachni::RPC::Exceptions::ConnectionError => e
            print_error "Could not connect to dispatcher at '#{@opts.server}'."
            print_debug "Error: #{e.to_s}."
            print_debug_backtrace e
            exit 1
        end

        begin
            # start the RPC client
            @instance = Arachni::RPC::Client::Instance.new( @opts,
                                                            @instance_info['url'],
                                                            @instance_info['token'] )
        rescue Arachni::RPC::Exceptions::ConnectionError => e
            print_error 'Could not connect to instance.'
            print_debug "Error: #{e.to_s}."
            print_debug_backtrace e
            exit 1
        end

        if @opts.platforms.any?
            begin
                Platform::Manager.new( @opts.platforms )
            rescue Platform::Error::Invalid => e
                @opts.platforms.clear
                print_error e
                print_info 'Available platforms are:'
                print_info Platform::Manager.new.valid.to_a.join( ', ' )
                print_line
                print_info 'Use the \'--lsplat\' parameter to see a detailed list of all available platforms.'
                exit 1
            end
        end

        if opts.lsplat
            platforms = @instance.framework.lsplat
            shutdown

            lsplat platforms
            exit
        end

        # If the user wants to see the available plugins grab them from the
        # server, output them, exit and shutdown the server.
        if !opts.lsplug.empty?
            plugins = @instance.framework.lsplug
            shutdown

            lsplug plugins
            exit
        end

        # If the user wants to see the available modules grab them from the
        # server, output them, exit and shutdown the server.
        if !opts.lsmod.empty?
            modules = @instance.framework.lsmod
            shutdown

            lsmod modules
            exit
        end

        # Check for missing url
        if !@opts.url
            print_error 'Missing url argument.'
            exit 1
        end

        @issues ||= []
    end

    def run
        begin
            # Start the show!
            @instance.service.scan prepare_rpc_options

            while busy?
                print_progress
                ::IO::select( nil, nil, nil, 5 )
                refresh_progress
            end
        rescue Interrupt
        rescue => e
            print_error e
            print_error_backtrace e
        end

        report_and_shutdown
    end

    private

    def print_progress
        # Clear existing terminal text.
        move_to_home
        cols, rows = HighLine::SystemExtensions.terminal_size
        (rows - 1).times{ print_line ' ' * cols }
        move_to_home

        print_banner

        print_issues
        print_line

        print_progressbar
        print_line

        print_stats
        print_line

        if has_errors?
            print_bad "This scan has encountered errors, see: #{error_log_file}"
            print_line
        end

        print_info "('Ctrl+C' aborts the scan and retrieves the report)"
        print_line

        flush
    end

    def has_errors?
        !!error_log_file
    end

    def print_progressbar
        print_info "#{progress_bar( stats['progress'], 61 )}"
        print_info "Est. remaining time: #{stats['eta']}"
    end

    def progress
        @progress or refresh_progress
    end

    def refresh_progress
        @error_messages_cnt ||= 0
        @issue_digests      ||= []

        @progress = @instance.service.
            progress( with:    [ :instances, :native_issues,
                                 errors: @error_messages_cnt ],
                      without: [ issues: @issue_digests ] )

        @issues |= @progress['issues']

        # Keep issue digests and error messages in order to ask not to retrieve
        # them on subsequent progress calls in order to save bandwidth.
        @issue_digests  |= @progress['issues'].map( &:digest )

        if @progress['errors'].any?
            error_log_file = @instance_info['url'].gsub( ':', '_' )
            @error_log_file = "#{error_log_file}.error.log"

            File.open( @error_log_file, 'a' ) { |f| f.write @progress['errors'].join( "\n" ) }

            @error_messages_cnt += @progress['errors'].size
        end

        @progress
    end

    def busy?
        !!progress['busy']
    end

    #
    # Laconically output the discovered issues.
    #
    # This method is used during a pause.
    #
    def print_issues
        super @issues
    end

    def prepare_rpc_options

        if @opts.grid? && @opts.spawns <= 0
            print_error "The 'spawns' option needs to be more than 1 for Grid scans."
            exit 1
        end

        if (@opts.grid? || @opts.spawns > 0) && @opts.restrict_paths.any?
            print_error "Option 'restrict_paths' is not supported when in High-Performance mode."
            exit 1
        end

        @opts.reports['stdout'] = {} if @opts.reports.empty?

        # No modules have been specified, set the mods to '*' (all).
        if !@opts.mods || @opts.mods.empty?
            @opts.mods = ['*']
        end

        # The user hasn't selected any elements to audit, set it to audit links, forms and cookies.
        if !@opts.audit_links && !@opts.audit_forms && !@opts.audit_cookies &&
            !@opts.audit_headers

            @opts.audit_links   = true
            @opts.audit_forms   = true
            @opts.audit_cookies = true
        end

        opts = @opts.to_h.dup

        # do not send these options over the wire
        [
            # this is bad, do not override the server's directory structure
            'dir',

            # this is of no use to the server is a local option for this UI
            'server',

            # profiles are not to be sent over the wire
            'load_profile',

            # report options should remain local
            'repopts',
            'repsave',

            'rpc_instance_port_range',
            'datastore',
            'reports',
            'cookies'
        ].each { |k| opts.delete( k ) }

        if opts['cookie_jar']
            opts['cookies'] = parse_cookie_jar( opts.delete( 'cookie_jar' ) )
        end

        @framework.plugins.default.each do |plugin|
            opts['plugins'][plugin] ||= {}
        end

        opts
    end

    # Grabs the report from the RPC server and runs the selected Arachni report module.
    def report_and_shutdown
        @framework.reports.load @opts.reports.keys

        print_status 'Shutting down and retrieving the report, please wait...'

        # Grab the AuditStore ad shutdown.
        audit_store = @instance.service.abort_and_report( :auditstore )
        shutdown

        # Run the loaded reports and get the generated filename.
        @framework.reports.run audit_store

        print_line
        print_stats
        print_line
    end

    def shutdown
        @instance.service.shutdown
    end

    def stats
        progress['stats']
    end

    def status
        progress['status']
    end

    def print_stats
        print_info "Status: #{status.to_s.capitalize}"

        sitemap_az = stats['sitemap_size']
        if status == 'crawling'
            print_info "Discovered #{sitemap_az} pages and counting."
        elsif status == 'auditing'
            print_info "Discovered #{sitemap_az} pages."
        end
        print_line

        print_info "Sent #{stats['requests']} requests."
        print_info "Received and analyzed #{stats['responses']} responses."
        print_info 'In ' + stats['time'].to_s
        print_info 'Average: ' + stats['avg'].to_s + ' requests/second.'

        print_line
        if status == 'auditing'
            print_info "Currently auditing           #{stats['current_page']}"
        end

        print_info "Burst response time total    #{stats['curr_res_time']}"
        print_info "Burst response count total   #{stats['curr_res_cnt']}"
        print_info "Burst average response time  #{stats['average_res_time']}"
        print_info "Burst average                #{stats['curr_avg']} requests/second"
        print_info "Timed-out requests           #{stats['time_out_count']}"
        print_info "Original max concurrency     #{@opts.http_req_limit}"
        print_info "Throttled max concurrency    #{stats['max_concurrency']}"
    end

    def parse_cookie_jar( jar )
        # make sure that the provided cookie-jar file exists
        if !File.exist?( jar )
            fail Arachni::Exceptions::NoCookieJar, "Cookie-jar '#{jar}' doesn't exist."
        end

        Arachni::Element::Cookie.from_file( @opts.url, jar ).inject({}) do |h, e|
            h.merge!( e.simple ); h
        end
    end

    # Outputs help/usage information.
    def usage
        super '--server host:port'

        print_line <<USAGE
    Distribution -----------------

    --server=<address:port>     Dispatcher server to use.
                                  (Used to provide scanner Instances.)

    --spawns=<integer>          How many slaves to spawn for a high-performance mult-Instance scan.
                                  (When no grid mode has been specified, all slaves will all be from the same Dispatcher machine.
                                    When a grid-mode has been specified, this option will be treated as a possible maximum and
                                    not a hard value.)

    --grid-mode=<mode>          Sets the Grid mode of operation for this scan.
                                  Valid modes are:
                                    * balance -- Slaves will be provided by the least burdened Grid Dispatchers.
                                    * aggregate -- In addition to balancing, slaves will all be from Dispatchers
                                        with unique bandwidth Pipe-IDs to result in application-level line-aggregation.

    --grid                      Shorthand for '--grid-mode=balance'.


    SSL --------------------------
    (Do *not* use encrypted keys!)

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
