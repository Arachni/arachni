=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.mixins + 'terminal'
require Options.paths.mixins + 'progress_bar'
require Options.paths.lib + 'rpc/client/instance'
require Options.paths.lib + 'utilities'
require_relative '../../utilities'
require Options.paths.lib + 'framework'

module UI::CLI
module RPC
module Client

# Provides a command-line RPC client/interface for an {RPC::Server::Instance}.
#
# This interface should be your first stop when looking into using/creating your
# own RPC client.
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
class Instance
    include Arachni::UI::Output
    include UI::CLI::Utilities

    include Arachni::Mixins::Terminal
    include Arachni::Mixins::ProgressBar

    attr_reader :error_log_file
    attr_reader :framework

    # @param    [Arachni::Options]  opts
    # @param    [RPC::Client::Instance] instance    Instance to control.
    def initialize( opts, instance )
        @opts     = opts
        @instance = instance

        clear_screen
        move_to_home

        # We don't need the framework for much, in this case only for report
        # generation, version number etc.
        @framework = Arachni::Framework.new( @opts )
        @issues    = []
    end

    def run
        begin
            # Start the show!
            @instance.service.scan prepare_rpc_options

            while busy?
                print_progress
                sleep 5
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
        empty_screen

        print_banner

        print_issues
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

    def progress
        @progress or refresh_progress
    end

    def refresh_progress
        @error_messages_cnt ||= 0
        @issue_digests      ||= []

        progress = @instance.service.progress(
            with:    [ :instances, :native_issues, errors: @error_messages_cnt ],
            without: [ issues: @issue_digests ]
        )

        return if !progress

        @progress = progress
        @issues  |= @progress['issues']

        @issues = @issues.sort_by(&:severity).reverse

        # Keep issue digests and error messages in order to ask not to retrieve
        # them on subsequent progress calls in order to save bandwidth.
        @issue_digests  |= @progress['issues'].map( &:digest )

        if @progress['errors'].any?
            error_log_file = @instance.url.gsub( ':', '_' )
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
        if @opts.dispatcher.grid? && @opts.spawns <= 0
            print_error "The 'spawns' option needs to be more than 1 for Grid scans."
            exit 1
        end

        if (@opts.dispatcher.grid? || @opts.spawns > 0) && @opts.scope.restrict_paths.any?
            print_error "Option 'scope_restrict_paths' is not supported when in High-Performance mode."
            exit 1
        end

        # No checks have been specified, set the mods to '*' (all).
        if @opts.checks.empty?
            @opts.checks = ['*']
        end

        if !@opts.audit.links && !@opts.audit.forms &&
            !@opts.audit.cookies && !@opts.audit.headers

            print_info 'No element audit options were specified, will audit ' <<
                           'links, forms and cookies.'
            print_line

            @opts.audit.elements :links, :forms, :cookies
        end

        opts = @opts.to_h.deep_clone
        %w(paths rpc dispatcher datastore).each { |k| opts.delete( k.to_sym ) }

        if opts[:http][:cookie_jar_filepath]
            opts[:http][:cookies] =
                parse_cookie_jar( opts[:http].delete( :cookie_jar_filepath ) )
        end

        @framework.plugins.default.each do |plugin|
            opts[:plugins][plugin] ||= {}
        end

        opts
    end

    # Grabs the report from the RPC server and runs the selected Arachni report.
    def report_and_shutdown
        print_status 'Shutting down and retrieving the report, please wait...'

        report = @instance.service.abort_and_report( :auditstore )
        shutdown

        @framework.reports.run :stdout, report

        filepath = report.save( @opts.datastore.report_path )
        filesize = (File.size( filepath ).to_f / 2**20).round(2)

        print_info "Report saved at: #{filepath} [#{filesize}MB]"

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
            if stats['current_pages']
                print_info 'Currently auditing:'

                stats['current_pages'].each.with_index do |url, i|
                    cnt = "[#{i + 1}]".rjust( stats['current_pages'].size.to_s.size + 4 )

                    if !url.to_s.empty?
                        print_info "#{cnt} #{url}"
                    else
                        print_info "#{cnt} Insufficient audit workload"
                    end
                end

                print_line
            else
                print_info "Currently auditing           #{stats['current_page']}"
            end
        end

        print_info "Burst response time total    #{stats['curr_res_time']}"
        print_info "Burst response count total   #{stats['curr_res_cnt']}"
        print_info "Burst average response time  #{stats['average_res_time']}"
        print_info "Burst average                #{stats['curr_avg']} requests/second"
        print_info "Timed-out requests           #{stats['time_out_count']}"
        print_info "Original max concurrency     #{@opts.http.request_concurrency}"
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

end

end
end
end
end
