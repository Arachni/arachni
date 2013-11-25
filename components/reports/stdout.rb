=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Default report.
#
# Outputs the issues to stdout, used with the CLI UI.<br/>
# All UIs must have a default report.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.4
#
class Arachni::Reports::Stdout < Arachni::Report::Base

    def run
        print_line
        print_line
        print_line "=" * 80
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
        print_info "Revision: #{auditstore.revision}"
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
        print_status 'Checks: ' + auditstore.options['mods'].join( ', ' )

        if auditstore.options['exclude'].any? ||
            auditstore.options['include'].any? ||
            auditstore.options['redundant'].any?

            print_line
            print_status 'Filters: '

            if auditstore.options['exclude'] && auditstore.options['exclude'].any?
                print_info "  Exclude:"
                auditstore.options['exclude'].each { |ex| print_info "    #{ex}" }
            end

            if auditstore.options['include'] && auditstore.options['include'].any?
                print_info "  Include:"
                auditstore.options['include'].each { |inc| print_info "    #{inc}" }
            end

            if auditstore.options['redundant'] && auditstore.options['redundant'].any?
                print_info "  Redundant:"
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

            trusted = issue.verification ? 'Untrusted' : 'Trusted'

            print_ok "[#{i+1}] #{trusted} -- #{issue.name}"
            print_info '~~~~~~~~~~~~~~~~~~~~'

            print_info "ID Hash:  #{issue.digest}"
            print_info "Severity: #{issue.severity}"
            print_info "URL:      #{issue.url}"
            print_info "Element:  #{issue.elem}"
            print_info "Method:   #{issue.method}" if issue.method
            print_info 'Tags:     ' + issue.tags.join( ', ' ) if issue.tags.is_a?( Array )
            print_info "Variable: #{issue.var}" if issue.var

            print_info 'Description: '
            print_info issue.description

            if issue.cwe && !issue.cwe.empty?
                print_line
                print_info "CWE: http://cwe.mitre.org/data/definitions/#{issue.cwe}.html"
            end

            print_line
            print_info 'Requires manual verification?: ' + issue.verification.to_s
            print_line

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

        # let the plugin formatters do their thing and print their results
        # and let our block handle the boring crap
        format_plugin_results do |results|
            print_line
            print_status results[:name]
            print_info '~~~~~~~~~~~~~~'

            print_info "Description: #{results[:description]}"
            print_line
        end
    end

    def self.info
        {
            name:        'Stdout',
            description: %q{Prints the results to standard output.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.4'
        }
    end

    def print_info_variations( issue )
        print_line
        print_status 'Variations'
        print_info '----------'

        issue.variations.each_with_index do |var, i|
            print_info "Variation #{i+1}:"
            print_info "URL: #{var['url']}"
            print_info "ID:  #{var['id']}"                          if var['id']
            print_info "Injected value:     #{var['injected'].inspect}"     if var['injected']
            print_info "Regular expression: #{var['regexp']}"       if var['regexp']
            print_info "Matched string:     #{var['regexp_match']}" if var['regexp_match']

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
end
