=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'erb'
require 'base64'
require 'cgi'

require Arachni::Options.instance.dir['lib'] + 'crypto/rsa_aes_cbc'

#
# Creates an HTML report of the audit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.1
#
class Arachni::Reports::HTML < Arachni::Report::Base
    include Arachni::Module::Utilities

    module Utils

        def normalize( str )
            return '' if !str || str.empty?
            str.encode( 'utf-8', 'binary', invalid: :replace, undef: :replace )
        end

        def escapeHTML( str )
            # carefully escapes HTML and converts to UTF-8
            # while removing invalid character sequences
            CGI.escapeHTML( normalize( str ) )
        end

        def for_anomalous_metamodules( audit_store, &block )
            audit_store.plugins.each do |metaname, data|
                next if !data[:tags] || !data[:tags].include?( 'anomaly' )
                block.call( metaname, data )
            end
        end

        def erb( tpl, params = {} )
            scope = TemplateScope.new( params )
            scope.add( :auditstore, auditstore )

            tpl = tpl.to_s + '.erb' if tpl.is_a?( Symbol )

            @@base_path ||= @base_path

            path = File.exist?( tpl ) ? tpl : @@base_path + tpl
            ERB.new( IO.read( path ) ).result( scope.get_binding )
        end
    end

    include Utils

    class TemplateScope
        include Utils

        ISSUES_URL = 'https://github.com/Arachni/arachni/issues'

        def initialize( params )
            add_hash( params )
        end

        def add_hash( params )
            params.each { |name, value| add( name, value ) }
            self
        end

        def add( name, value )
            self.class.send( :attr_accessor, name )
            instance_variable_set( "@#{name.to_s}", value )
            self
        end

        def format_issue( hash )
            idx, issue = find_issue_by_hash( hash )
            erb :issue, idx: idx, issue: issue
        end

        def prep_description( str )
            Arachni::Reports::HTML.prep_description( str )
        end

        def find_issue_by_hash( hash )
            auditstore.issues.each.with_index do |issue, i|
                return [i+1, issue] if issue.digest == hash
            end
            nil
        end

        def get_meta_info( name )
            auditstore.plugins['metamodules'][:results][name]
        end

        def get_plugin_info( name )
            auditstore.plugins[name]
        end

        def js_multiline( str )
            "\"" + normalize( str ).gsub( "\n", '\n' ) + "\""
        end

        def get_binding
            binding
        end
    end

    #
    # Runs the HTML report.
    #
    def run
        print_line
        print_status 'Creating HTML report...'

        plugins    = format_plugin_results( auditstore.plugins )
        @base_path = File.dirname( options['tpl'] ) + '/' +
            File.basename( options['tpl'], '.erb' ) + '/'

        title_url = auditstore.options['url']
        begin
            title_url = uri_parse( auditstore.options['url'] ).host
        rescue
        end

        params = prepare_data.merge(
            title_url:   escapeHTML( title_url ),
            audit_store: auditstore,
            plugins:     plugins,
            base_path:   @base_path
        )

        File.open( outfile, 'w' ) { |f| f.write( erb( options['tpl'], params ) ) }

        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:        'HTML Report',
            description: %q{Exports a report as an HTML document.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3.1',
            options:     [
                Options::Path.new( 'tpl', [false, 'Template to use.', File.dirname( __FILE__ ) + '/html/default.erb'] ),
                Options.outfile( '.html' )
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
                Issue::Severity::HIGH          => 0,
                Issue::Severity::MEDIUM        => 0,
                Issue::Severity::LOW           => 0,
                Issue::Severity::INFORMATIONAL => 0
            },
            issues:           {},
            trusted_issues:   {},
            untrusted_issues: {},
            elements:         {
                Issue::Element::FORM   => 0,
                Issue::Element::LINK   => 0,
                Issue::Element::COOKIE => 0,
                Issue::Element::HEADER => 0,
                Issue::Element::BODY   => 0,
                Issue::Element::PATH   => 0,
                Issue::Element::SERVER => 0
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
        total_verifications = 0

        crypto_issues = []

        filtered_hashes  = []
        anomalous_hashes = []

        anomalous_meta_results = {}
        for_anomalous_metamodules( auditstore ) do |metaname, data|
            anomalous_meta_results[metaname] = data
        end

        auditstore.issues.each.with_index do |issue, i|

            graph_data[:severities][issue.severity] += 1
            total_severities += 1

            graph_data[:issues][issue.name] ||= 0
            graph_data[:issues][issue.name] += 1


            graph_data[:elements][issue.elem] += 1
            total_elements += 1

            verification = issue.verification ? 'Yes' : 'No'
            graph_data[:verification][verification] += 1
            total_verifications += 1

            issue.variations.each_with_index do |variation, j|

                if variation['response'] && !variation['response'].empty?
                    variation['response'] = normalize( variation['response'] )

                    auditstore.issues[i].variations[j]['escaped_response'] =
                        Base64.encode64( variation['response'] ).gsub( /\n/, '' )
                end

                response = {}
                if !variation['headers']['response'].is_a?( Hash )
                    variation['headers']['response'].split( "\n" ).each do |line|
                        field, value = line.split( ':', 2 )
                        next if !value
                        response[field] = value
                    end
                end

                variation['headers']['response'] = response.dup
            end

            if !anomalous?( anomalous_meta_results, issue )
                filtered_hashes << issue.digest
                graph_data[:trust]['Trusted'] += 1
                graph_data[:trusted_issues][issue.name]   ||= 0
                graph_data[:trusted_issues][issue.name]    += 1
                graph_data[:untrusted_issues][issue.name] ||= 0
            else
                anomalous_hashes << issue.digest
                graph_data[:trust]['Untrusted'] += 1
                graph_data[:untrusted_issues][issue.name] ||= 0
                graph_data[:untrusted_issues][issue.name]  += 1
                graph_data[:trusted_issues][issue.name]   ||= 0
            end

        end

        graph_data[:severities].each do |severity, cnt|
            graph_data[:severities][severity] ||= 0
            begin
                graph_data[:severities][severity] = ((cnt / Float( total_severities ) ) * 100).to_i
            rescue
            end
        end

        graph_data[:elements].each do |elem, cnt|
            graph_data[:elements][elem] ||= 0
            begin
                graph_data[:elements][elem] = ((cnt / Float( total_elements ) ) * 100).to_i
            rescue
            end
        end

        graph_data[:verification].each do |verification, cnt|
            graph_data[:verification][verification] ||= 0
            begin
                graph_data[:verification][verification] = ((cnt / Float( total_verifications ) ) * 100).to_i
            rescue
            end
        end

        {
            graph_data:             graph_data,
            total_severities:       total_severities,
            total_elements:         total_elements,
            total_verifications:    total_verifications,
            crypto_issues:          crypto_issues,
            filtered_hashes:        filtered_hashes,
            anomalous_hashes:       anomalous_hashes,
            anomalous_meta_results: anomalous_meta_results
        }

    end

    def anomalous?( anomalous_meta_results, issue )
        anomalous_meta_results.each_pair do |metaname, data|
            data[:results].each do |m_issue|
                return true if m_issue['hash'] == issue._hash
            end
        end
        false
    end

end
