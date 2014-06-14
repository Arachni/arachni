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
            code = code.dup.encode( 'ascii-8bit', invalid: :replace, undef: :replace )
            CodeRay.scan( code, language ).div( options )
        end

        def data_dump( data )
            "<div class='data-dump'>#{data.ai( plain: true, html: true )}</div>"
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
            "issues-#{'un' if issue.untrusted?}trusted-severity-" <<
                "#{issue.severity}-#{issue.check[:shortname]}-#{issue.digest}"
        end

        def erb( tpl, params = {} )
            scope = TemplateScope.new( params )

            tpl = tpl.to_s + '.erb' if tpl.is_a?( Symbol )

            path = File.exist?( tpl ) ? tpl : scope.template_path + tpl
            ERB.new( IO.read( path ) ).result( scope.get_binding )
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
            Arachni::Reporters::HTML.prep_description( str )
        end

        def get_plugin_info( name )
            report.plugins[name]
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
        # plugins    = format_plugin_results( report.plugins )
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

            if grouped_issues[:trusted][by_severity.first.severity].empty?
                grouped_issues[:trusted].delete by_severity.first.severity
            end

            if grouped_issues[:untrusted][by_severity.first.severity].empty?
                grouped_issues[:untrusted].delete by_severity.first.severity
            end
        end

        prepare_data.merge(
            report:         report,
            grouped_issues: grouped_issues,
            template_path:  template_path,
            plugins:        {}
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
            issues:           {},
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

            if issue.variations.first.trusted?
                has_trusted_issues = true
                graph_data[:trust]['Trusted'] += 1
                graph_data[:trusted_issues][issue.name]   ||= 0
                graph_data[:trusted_issues][issue.name]    += 1
                graph_data[:untrusted_issues][issue.name] ||= 0
            else
                has_untrusted_issues = true
                graph_data[:trust]['Untrusted'] += 1
                graph_data[:untrusted_issues][issue.name] ||= 0
                graph_data[:untrusted_issues][issue.name]  += 1
                graph_data[:trusted_issues][issue.name]   ||= 0
            end

        end

        {
            graph_data:           graph_data,
            total_severities:     total_severities,
            total_elements:       total_elements,
            has_trusted_issues:   has_trusted_issues,
            has_untrusted_issues: has_untrusted_issues
        }
    end

end
