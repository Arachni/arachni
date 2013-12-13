=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Outputs the issues to stdout, used with the CLI UI.
# All UIs must have a default report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.3
class Arachni::Reports::Stdout < Arachni::Report::Base

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

        print_info "Version:  #{auditstore.version}"
        print_info "Audit started on:  #{auditstore.start_datetime}"
        print_info "Audit finished on: #{auditstore.finish_datetime}"
        print_info "Runtime: #{auditstore.delta_time}"
        print_line
        print_info "URL: #{auditstore.options['url']}"
        print_info "User agent: #{auditstore.options['user_agent']}"
        print_line
        print_status 'Audited elements: '
        print_info '* Links'    if auditstore.options['audit_links']
        print_info '* Forms'    if auditstore.options['audit_forms']
        print_info '* Cookies'  if auditstore.options['audit_cookies']
        print_info '* Headers'  if auditstore.options['audit_headers']
        print_line
        print_status "Checks: #{auditstore.options['checks'].join( ', ' )}"

        if auditstore.options['exclude'].any? || auditstore.options['include'].any? ||
            auditstore.options['redundant'].any?

            print_line
            print_status 'Filters: '

            if auditstore.options['exclude'] && auditstore.options['exclude'].any?
                print_info '  Exclude:'
                auditstore.options['exclude'].each { |ex| print_info "    #{ex}" }
            end

            if auditstore.options['include'] && auditstore.options['include'].any?
                print_info '  Include:'
                auditstore.options['include'].each { |inc| print_info "    #{inc}" }
            end

            if auditstore.options['redundant'] && auditstore.options['redundant'].any?
                print_info '  Redundant:'
                auditstore.options['redundant'].each do |regexp, counter|
                    print_info "    #{regexp}:#{counter}"
                end
            end
        end

        if auditstore.options['cookies'] && auditstore.options['cookies'].any?
            print_line
            print_status 'Cookies: '
            auditstore.options['cookies'].each do |cookie|
                print_info "  #{cookie[0]} = #{cookie[1]}"
            end
        end

        print_line
        print_info '==========================='
        print_line
        print_ok "#{auditstore.issues.size} issues were detected."
        print_line

        auditstore.issues.each_with_index do |issue, i|

            trusted = issue.trusted? ? 'Trusted' : 'Untrusted'

            print_ok "[#{i+1}] #{trusted} -- #{issue.name}"
            print_info '~~~~~~~~~~~~~~~~~~~~'

            print_info "ID Hash:  #{issue.digest}"
            print_info "Severity: #{issue.severity}"
            print_info "URL:      #{issue.vector.action}"
            print_info "Element:  #{issue.vector.type}"

            if issue.active?
                print_info "Method:   #{issue.vector.method}"
                print_info "Variable: #{issue.vector.affected_input_name}"
            end

            print_info 'Tags:     ' + issue.tags.join( ', ' ) if issue.tags.is_a?( Array )

            print_info 'Description: '
            print_info issue.description

            if issue.cwe_url
                print_line
                print_info issue.cwe_url
            end

            if issue.references
                print_info 'References:'
                issue.references.each{ |ref| print_info "  #{ref[0]} - #{ref[1]}" }
            end

            print_info_variations issue
            print_line
        end

        return if auditstore.plugins.empty?

        print_line
        print_ok 'Plugin data:'
        print_info '---------------'
        print_line

        # Let the plugin formatters do their thing and print the plugin results
        # and let our block handle the boring crap.
        format_plugin_results do |results|
            print_line
            print_status results[:name]
            print_info '~~~~~~~~~~~~~~'

            print_info "Description: #{results[:description]}"
            print_line
        end
    end

    def print_info_variations( issue )
        print_line
        print_status 'Variations'
        print_info '----------'

        issue.variations.each_with_index do |var, i|
            print_info "Variation #{i+1}:"

            if var.active?
                print_info "Injected:  #{var.vector.affected_input_value.inspect}"
            end

            print_info "Signature: #{var.signature}" if var.signature
            print_info "Proof:     #{var.proof}"

            next if var.remarks.empty?

            print_line
            print_info 'Remarks'
            print_info '-------'
            var.remarks.each do |logger, remarks|
                print_info "  By #{logger}:"
                remarks.each do |remark|
                    print_info "    *  #{word_wrap remark}"
                end
            end

            print_line
        end
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3'
        }
    end

end
