=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'coderay'
require 'json'
require 'erb'
require 'base64'
require 'cgi'

# Creates an HTML report with scan results.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.3.3
class Arachni::Reporters::HTML < Arachni::Reporter::Base

    module TemplateUtilities

        def base64_encode( string )
            Base64.encode64( string ).gsub( /\n/, '' )
        end

        def normalize( str )
            str.to_s.recode
        end

        def code_highlight( code, language = :html, options = {} )
            return if !code

            lines = CodeRay.scan( code.recode, language ).html( css: :style ).lines

            if options[:from]
                from = [0, options[:from]].max
            else
                from = 0
            end

            if options[:to]
                to = [lines.size, options[:to]].min
            else
                to = lines.size - 1
            end

            code = '<div class="code-container"><table class="CodeRay"><tbody><tr><td class="line-numbers"><pre>'

            from.upto(to) do |i|
                if options[:anchor_id]
                    line = "<a href='#{id_to_location "#{options[:anchor_id]}-#{i}"}'>#{i}</a>"
                else
                    line = "#{i}"
                end

                if options[:breakpoint] && options[:breakpoint] == i
                    code << "<span class='breakpoint'>#{line}</span>"
                else
                    code << line
                end

                code << "\n"
            end

            code << '</pre></td><td class="code"><pre>'

            from.upto(to) do |i|
                line = "<span id='#{options[:anchor_id]}-#{i}'>#{lines[i]}</span>"

                if options[:breakpoint] && options[:breakpoint] == i
                    code << "<span class='breakpoint'>#{line}</span>"
                else
                    code << line.to_s
                end
            end

            code + '</pre></td></tr></tbody></table></div>'
        end

        def data_dump( data )
            ap = AwesomePrint::Inspector.new( plain: true, html: true )
            "<pre class='data-dump'>#{ap.awesome( data )}</pre>"
        end

        # Carefully escapes HTML and converts to UTF-8 while removing
        # invalid character sequences.
        def escapeHTML( str )
            CGI.escapeHTML( normalize( str ) )
        end

        def highlight_issue_page_body( issue, span_class )
            return escapeHTML( issue.page.body ) if !issue.page.body.include?( issue.proof )

            escaped_proof         = escapeHTML( issue.proof )
            escaped_response_body = escapeHTML( issue.page.body )

            escaped_response_body.gsub(
                escaped_proof,
                "<span class=\"#{span_class}\">#{escaped_proof}</span>"
            )
        end

        def issue_location( issue )
            id_to_location( issue_id( issue ) )
        end

        def issue_id( issue )
            # Trust evaluation needs to come from variations.
            untrusted = issue.variation? ?
                issue.untrusted? : issue.variations.first.untrusted?

            # Generic issue data needs to come from the parent.
            issue = report.issue_by_digest( issue.digest ) if issue.variation?

            "issues-#{'un' if untrusted}trusted-severity-" <<
                "#{issue.severity}-#{issue.check[:shortname]}-#{issue.digest}"
        end

        def id_to_location( id )
            "#!/#{id.gsub( '-', '/' )}"
        end

        def erb( tpl, params = {} )
            scope = TemplateScope.new( params )

            tpl = tpl.to_s + '.erb' if tpl.is_a?( Symbol )

            path = File.exist?( tpl ) ? tpl : scope.template_path + tpl

            ERB.new( IO.read( path ).recode ).result( scope.get_binding )
        rescue
            ap tpl
            raise
        end
    end

    include TemplateUtilities

    class TemplateScope
        include TemplateUtilities

        ISSUES_URL = 'https://github.com/Arachni/arachni/issues'

        def initialize( params = {} )
            update params
            update self.class.global_data
        end

        def update( params )
            params.each { |name, value| self[name] = value }
            self
        end

        def []=( name, value )
            self.class.send( :attr_accessor, name )
            instance_variable_set( "@#{name.to_s}", value )
            self
        end

        def prep_description( str )
            escapeHTML Arachni::Reporters::HTML.prep_description( str )
        end

        def get_plugin_info( name )
            report.plugins[name.to_sym]
        end

        def js_multiline( str )
            "\"" + normalize( str ).gsub( "\n", '\n' ) + "\""
        end

        def get_binding
            binding
        end

        def self.global_data=( data )
            @global_data = data
        end

        def self.global_data
            @global_data
        end
    end

    def global_data
        plugins       = format_plugin_results( report.plugins )
        template_path = File.dirname( options[:template] ) + '/' +
            File.basename( options[:template], '.erb' ) + '/'

        grouped_issues = {
            trusted:   {},
            untrusted: {}
        }

        Arachni::Issue::Severity::ORDER.each do |severity|
            by_severity = report.issues.select { |i| i.severity.to_sym == severity }
            next if by_severity.empty?

            by_name = {}
            by_severity.each do |issue|
                by_name[issue.name] ||= []
                by_name[issue.name] << issue
            end
            next if by_name.empty?

            grouped_issues[:trusted][by_severity.first.severity] =
                by_name.inject({}) do |h, (name, issues)|
                    i = issues.select { |i| !i.variations.find(&:untrusted?) }
                    next h if i.empty?

                    h[name] = i
                    h
                end

            grouped_issues[:untrusted][by_severity.first.severity] =
                by_name.inject({}) do |h, (name, issues)|
                    i = issues.select { |i| i.variations.find(&:untrusted?) }
                    next h if i.empty?

                    h[name] = i
                    h
                end

            [:trusted, :untrusted].each do |t|
                if grouped_issues[t][by_severity.first.severity].empty?
                    grouped_issues[t].delete by_severity.first.severity
                end
            end
        end

        [:trusted, :untrusted].each do |t|
            grouped_issues.delete( t ) if grouped_issues[t].empty?
        end

        prepare_data.merge(
            report:         report,
            grouped_issues: grouped_issues,
            template_path:  template_path,
            plugins:        plugins
        )
    end

    # Runs the HTML report.
    def run
        print_line
        print_status 'Creating HTML report...'

        TemplateScope.global_data = global_data

        File.open( outfile, 'w' ) { |f| f.write( erb( options[:template] ) ) }

        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:         'HTML',
            description:  %q{Exports the audit results as an HTML (.html) file.},
            content_type: 'text/html',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.3.2',
            options:      [
                Options::Path.new( :template,
                    description: 'Template to use.',
                    default:     File.dirname( __FILE__ ) + '/html/default.erb'
                ),
                Options.outfile( '.html' ),
                Options.skip_responses
            ]
        }
    end

    private

    def self.prep_description( str )
        placeholder =  '--' + rand( 1000 ).to_s + '--'
        cstr = str.gsub( /^\s*$/xm, placeholder )
        cstr.gsub!( /^\s*/xm, '' )
        cstr.gsub!( placeholder, "\n" )
        cstr.chomp
    end

    def prepare_data
        graph_data = {
            severities:       {
                Severity::HIGH.to_sym          => 0,
                Severity::MEDIUM.to_sym        => 0,
                Severity::LOW.to_sym           => 0,
                Severity::INFORMATIONAL.to_sym => 0
            },
            severity_for_issue: {},
            severity_index_for_issue: {},
            issues:           {},
            issues_shortnames: Set.new,
            trusted_issues:   {},
            untrusted_issues: {},
            elements:         {
                Element::Form.type   => 0,
                Element::Form::DOM.type   => 0,
                Element::Link.type   => 0,
                Element::Link::DOM.type   => 0,
                Element::Cookie.type => 0,
                Element::Cookie::DOM.type => 0,
                Element::LinkTemplate.type => 0,
                Element::LinkTemplate::DOM.type => 0,
                Element::Header.type => 0,
                Element::Body.type   => 0,
                Element::Path.type   => 0,
                Element::Server.type => 0,
                Element::GenericDOM.type => 0
            },
            verification:     {
                'Yes' => 0,
                'No'  => 0
            },
            trust:            {
                'Trusted'   => 0,
                'Untrusted' => 0
            }
        }

        total_severities = 0
        total_elements   = 0

        has_trusted_issues   = false
        has_untrusted_issues = false

        report.issues.each.with_index do |issue, i|
            graph_data[:severities][issue.severity.to_sym] += 1
            total_severities += 1

            graph_data[:issues][issue.name] ||= 0
            graph_data[:issues][issue.name] += 1


            graph_data[:elements][issue.vector.class.type] += 1
            total_elements += 1

            verification = issue.untrusted? ? 'Yes' : 'No'
            graph_data[:verification][verification] += 1

            graph_data[:untrusted_severities] ||= {}
            graph_data[:untrusted_severities][issue.severity.to_sym] ||= 0

            graph_data[:trusted_severities] ||= {}
            graph_data[:trusted_severities][issue.severity.to_sym] ||= 0

            graph_data[:trusted_issues][issue.name]   ||= 0
            graph_data[:untrusted_issues][issue.name] ||= 0

            graph_data[:issues_shortnames] << issue.check[:shortname]
            graph_data[:severity_for_issue][issue.check[:shortname]] = issue.severity.to_s

            graph_data[:severity_index_for_issue][issue.name] =
                Issue::Severity::ORDER.reverse.index( issue.severity.to_sym ) + 1

            if issue.variations.first.trusted?
                has_trusted_issues = true
                graph_data[:trust]['Trusted'] += 1
                graph_data[:trusted_severities][issue.severity.to_sym] += 1
                graph_data[:trusted_issues][issue.name] += 1
            else
                has_untrusted_issues = true
                graph_data[:trust]['Untrusted'] += 1
                graph_data[:untrusted_severities][issue.severity.to_sym] += 1
                graph_data[:untrusted_issues][issue.name]  += 1
            end
        end

        graph_data[:issues_shortnames] = graph_data[:issues_shortnames].to_a

        {
            graph_data:           graph_data,
            total_severities:     total_severities,
            total_elements:       total_elements,
            has_trusted_issues:   has_trusted_issues,
            has_untrusted_issues: has_untrusted_issues
        }
    end

end
