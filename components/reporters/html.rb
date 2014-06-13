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

        def erb( tpl, params = {} )
            scope = TemplateScope.new(
                params.merge(
                    report:        report,
                    template_path: @template_path
                )
            )

            tpl = tpl.to_s + '.erb' if tpl.is_a?( Symbol )

            ap tpl
            path = File.exist?( tpl ) ? tpl : @template_path + tpl
            ERB.new( IO.read( path ) ).result( scope.get_binding )
        end
    end

    include TemplateUtilities

    class TemplateScope
        include TemplateUtilities

        ISSUES_URL = 'https://github.com/Arachni/arachni/issues'

        def initialize( params )
            update( params )
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
    end

    # Runs the HTML report.
    def run
        print_line
        print_status 'Creating HTML report...'

        # plugins    = format_plugin_results( report.plugins )
        @template_path = File.dirname( options[:template] ) + '/' +
            File.basename( options[:template], '.erb' ) + '/'

        params = prepare_data.merge(
            title_url:   uri_parse( report.url ).host,
            audit_store: report,
            plugins:     {}
        )

        File.open( outfile, 'w' ) { |f| f.write( erb( options[:template], params ) ) }

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
                Element::Server.type => 0
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


            graph_data[:elements][issue.vector.type] += 1
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
