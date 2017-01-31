=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'framework'

module Arachni
module UI::CLI

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class RestoredFramework < Framework
    require_relative 'restored_framework/option_parser'

    private

    # It parses and processes CLI options.
    #
    # Loads checks, reports, saves/loads profiles etc.
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    def parse_options
        parser = OptionParser.new
        parser.report
        parser.snapshot
        parser.timeout
        parser.timeout_suspend
        parser.parse

        @timeout         = parser.get_timeout
        @timeout_suspend = parser.timeout_suspend?

        if parser.print_metadata?
            print_metadata Snapshot.read_metadata( parser.snapshot_path )
            exit
        end

        framework.restore parser.snapshot_path
    end

    def print_metadata( metadata )
        data  = metadata[:summary][:data]
        state = metadata[:summary][:state]

        print_ok "#{state[:options][:url]} - #{metadata[:timestamp]} (#{metadata[:version]})"
        print_line

        print_status 'Data'
        print_status '-----'
        print_line

        print_info 'Framework'
        framework = data[:framework]
        print_info "  Sitemap size:    #{framework[:sitemap]}"
        print_info "  Page queue size: #{framework[:page_queue]}"
        print_info "  URL queue size:  #{framework[:url_queue]}"

        print_line

        print_info 'Issues'
        issues = data[:issues]
        print_info "  Total: #{issues[:total]}"
        print_info '  By severity'
        issues[:by_severity].each do |severity, count|
            print_info "    - #{severity.to_s.capitalize}: #{count}"
        end

        print_info '  By type:'
        issues[:by_type].each do |type, count|
            print_info "    - #{type}: #{count}"
        end

        print_info '  By check:'
        issues[:by_check].each do |check, count|
            print_info "    - #{check}: #{count}"
        end

        print_line
        plugins = data[:plugins]
        names = plugins[:names].any? ? plugins[:names].join( ', ' ) : '[None]'
        print_info "Plugins with results: #{names}"

        print_line

        print_status 'State'
        print_status '-----'

        print_line
        print_info 'Framework'
        framework = state[:framework]
        print_info "  Audited pages:  #{framework[:audited_page_count]}"
        print_info "  Browser states: #{framework[:browser_states]}"

        print_line
        print_info "HTTP cookies: #{'[None]' if state[:http][:cookies].empty?}"
        state[:http][:cookies].each do |cookie|
            print_info "    - #{cookie}"
        end

        print_line
        plugins = state[:plugins]
        names = plugins[:names].any? ? plugins[:names].join( ', ' ) : '[None]'
        print_info "Suspended plugins: #{names}"

        print_line
        print_info 'Options'
        options = state[:options]

        checks = options[:checks].any? ? options[:checks].join( ', ' ) : '[None]'
        print_info "  Checks:  #{checks}"

        plugins = options[:plugins].any? ? options[:plugins].join( ', ' ) : '[None]'
        print_info "  Plugins: #{plugins}"

        print_line
        print_info "Audit operations performed: #{state[:audit][:total]}"

        print_line
        print_info 'Elements seen'
        element_filter = state[:element_filter]
        print_info "  Forms:   #{element_filter[:forms]}"
        print_info "  Links:   #{element_filter[:links]}"
        print_info "  Cookies: #{element_filter[:cookies]}"
    end

end

end
end
