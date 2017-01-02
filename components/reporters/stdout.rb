=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Outputs the issues to stdout, used with the CLI UI.
# All UIs must have a default report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Reporters::Stdout < Arachni::Reporter::Base

    def run
        # We're going to be printing a lot of stuff, not just simple status
        # messages, so avoid prefixing every message with the component's name.
        depersonalize_output

        print_line
        print_line
        print_line '=' * 80
        print_line
        print_line

        print_ok 'Web Application Security Report - Arachni Framework'
        print_line
        print_info "Report generated on: #{Time.now}"
        print_info "Report false positives at: #{REPORT_FP}"
        print_line

        print_ok 'System settings:'
        print_info '---------------'

        print_info "Version:           #{report.version}"
        print_info "Seed:              #{report.seed}"
        print_info "Audit started on:  #{report.start_datetime}"
        print_info "Audit finished on: #{report.finish_datetime}"
        print_info "Runtime:           #{report.delta_time}"
        print_line
        print_info "URL:        #{report.options[:url]}"
        print_info "User agent: #{report.options[:http][:user_agent]}"
        print_line
        print_status 'Audited elements: '
        print_info '* Links'     if report.options[:audit][:links]
        print_info '* Forms'     if report.options[:audit][:forms]
        print_info '* Cookies'   if report.options[:audit][:cookies]
        print_info '* Headers'   if report.options[:audit][:headers]
        print_info '* XMLs'      if report.options[:audit][:xmls]
        print_info '* JSONs'     if report.options[:audit][:jsons]
        print_info '* UI inputs' if report.options[:audit][:ui_inputs]
        print_info '* UI forms'  if report.options[:audit][:ui_forms]
        print_line
        print_status "Checks: #{report.options[:checks].join( ', ' )}"

        if report.options[:scope][:exclude_path_patterns].any? ||
            report.options[:scope][:include_path_patterns].any? ||
            report.options[:scope][:redundant_path_patterns].any?

            print_line
            print_status 'Filters: '

            if report.options[:scope][:exclude_path_patterns] &&
                report.options[:scope][:exclude_path_patterns].any?

                print_info '  Exclude:'
                report.options[:scope][:exclude_path_patterns].each { |ex| print_info "    #{ex}" }
            end

            if report.options[:scope][:include_path_patterns] &&
                report.options[:scope][:include_path_patterns].any?

                print_info '  Include:'
                report.options[:scope][:include_path_patterns].each { |inc| print_info "    #{inc}" }
            end

            if report.options[:scope][:redundant_path_patterns] &&
                report.options[:scope][:redundant_path_patterns].any?

                print_info '  Redundant:'
                report.options[:scope][:redundant_path_patterns].each do |regexp, counter|
                    print_info "    #{regexp}:#{counter}"
                end
            end
        end

        if report.options[:cookies] && report.options[:cookies].any?
            print_line
            print_status 'Cookies: '
            report.options[:cookies].each do |cookie|
                print_info "  #{cookie[0]} = #{cookie[1]}"
            end
        end

        print_line
        print_info '==========================='
        print_line
        print_ok "#{report.issues.size} issues were detected."
        print_line

        report.issues.each_with_index do |issue, i|
            trusted = issue.trusted? ? 'Trusted' : 'Untrusted'

            print_ok "[#{i+1}] #{issue.name} (#{trusted})"
            print_info '~~~~~~~~~~~~~~~~~~~~'

            print_info "Digest:     #{issue.digest}"
            print_info "Severity:   #{issue.severity.to_s.capitalize}"
            print_info 'Description: '
            print_info issue.description
            print_info "Tags: #{issue.tags.join(', ')}" if issue.tags.is_a?( Array )

            if issue.cwe_url
                print_line
                print_info "CWE: #{issue.cwe_url}"
            end

            if issue.references
                print_info 'References:'
                issue.references.each{ |ref| print_info "  #{ref[0]} - #{ref[1]}" }
            end

            print_line
            print_info "URL:        #{issue.vector.action}"
            print_info "Element:    #{issue.vector.type}"

            if issue.vector.respond_to? :inputs
                print_info "All inputs: #{issue.vector.inputs.keys.join(', ')}"
            end

            if issue.active?
                print_info "Method:     #{issue.vector.method.to_s.upcase}"
                print_info "Input name: #{issue.affected_input_name}"
            end

            print_info_issue_details issue
            print_line
        end

        return if report.plugins.empty?

        print_line
        print_ok 'Plugin data:'
        print_info '---------------'
        print_line

        # Let the plugin formatters do their thing and print the plugin results
        # and let our block handle the boring crap.
        format_plugin_results do |name|
            print_line
            print_status report.plugins[name][:name]
            print_info '~~~~~~~~~~~~~~'

            print_info "Description: #{report.plugins[name][:description]}"
            print_line
        end
    end

    def print_info_issue_details( issue )
        print_line
        if issue.active?
            if issue.vector.respond_to? :seed
                print_info "Seed:      #{issue.vector.seed.inspect}"
            end

            print_info "Injected:  #{issue.vector.affected_input_value.inspect}"
        end

        print_info "Signature: #{issue.signature}"     if issue.signature
        print_info "Proof:     #{issue.proof.inspect}" if issue.proof

        print_line
        print_info "Referring page: #{issue.referring_page.dom.url}"
        if issue.referring_page.dom.transitions.any?
            print_info 'DOM transitions:'
            issue.referring_page.dom.print_transitions( method(:print_info), '    ' )
        end

        print_line
        print_info "Affected page:  #{issue.page.dom.url}"

        if !issue.request.to_s.empty?
            print_info "HTTP request\n#{issue.request}"
        end

        if issue.page.dom.transitions.any?
            print_info 'DOM transitions:'
            issue.page.dom.print_transitions( method(:print_info), '    ' )
        end

        return if issue.remarks.empty?

        print_line
        print_info 'Remarks'
        print_info '-------'
        issue.remarks.each do |logger, remarks|
            print_info "  By #{logger}:"
            remarks.each do |remark|
                print_info "    *  #{word_wrap remark}"
            end
        end

        print_line
    end

    # Stolen from Rails.
    def word_wrap( text, line_width = 80 )
        return '' if text.to_s.empty?
        text.split("\n").collect do |line|
            line.length > line_width ?
                line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
    end

    def self.info
        {
            name:        'Stdout',
            description: %q{Prints the results to standard output.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3.3'
        }
    end

end
