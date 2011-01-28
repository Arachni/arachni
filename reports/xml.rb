=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'base64'

module Arachni

require Arachni::Options.instance.dir['reports'] + '/xml/buffer.rb'

module Reports

#
# Creates an XML report of the audit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class XML < Arachni::Report::Base

    include Arachni::Reports::Buffer

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store = audit_store
        @outfile     = options['outfile']

        # XML buffer
        @__buffer = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
    end

    def run( )

        print_line( )
        print_status( 'Creating XML report...' )

        start_tag( 'arachni_report' )

        simple_tag( 'title', 'Web Application Security Report - Arachni Framework' )
        simple_tag( 'generated_on', Time.now.to_s )
        simple_tag( 'report_false_positives', REPORT_FP )

        start_tag( 'system' )
        simple_tag( 'version', @audit_store.version )
        simple_tag( 'revision', @audit_store.revision )
        simple_tag( 'start_datetime', @audit_store.start_datetime )
        simple_tag( 'finish_datetime', @audit_store.finish_datetime )
        simple_tag( 'delta_time', @audit_store.delta_time )

        simple_tag( 'url', @audit_store.options['url'] )
        simple_tag( 'user_agent', @audit_store.options['user_agent'] )

        start_tag( 'audited_elements' )
        simple_tag( 'element', 'links' ) if @audit_store.options['audit_links']
        simple_tag( 'element', 'forms' ) if @audit_store.options['audit_forms']
        simple_tag( 'element', 'cookies' ) if @audit_store.options['audit_cookies']
        simple_tag( 'element', 'headers' ) if @audit_store.options['audit_headers']
        end_tag( 'audited_elements' )

        start_tag( 'modules')
        @audit_store.options['mods'].each { |mod| add_mod( mod ) }
        end_tag( 'modules' )

        start_tag( 'filters' )
        if @audit_store.options['exclude']
            start_tag( "exclude" )
            @audit_store.options['exclude'].each {
                |ex|
                simple_tag( 'regexp', ex )
            }
            end_tag( "exclude" )
        end


        if @audit_store.options['include']
            start_tag( "include" )
            @audit_store.options['include'].each {
                |inc|
                simple_tag( 'regexp', inc )
            }
            end_tag( "include" )
        end


        if @audit_store.options['redundant']
            start_tag( "redundant" )
            @audit_store.options['redundant'].each {
                |red|
                simple_tag( 'filter', red['regexp'] + ':' + red['count'].to_s )
            }
            end_tag( "redundant" )
        end
        end_tag( 'filters' )


        start_tag( 'cookies' )
        if( @audit_store.options['cookies'] )
            @audit_store.options['cookies'].each {
                |name, value|
                add_cookie( name, value )
            }
        end
        end_tag( 'cookies' )


        end_tag( 'system' )


        start_tag( 'issues' )
        @audit_store.issues.each {
            |issue|

            start_tag( 'issue' )
            simple_tag( 'name', issue.name )

            simple_tag( 'url', issue.url )
            simple_tag( 'element', issue.elem )
            simple_tag( 'variable', issue.var )
            simple_tag( 'description', issue.description )
            simple_tag( 'manual_verification', issue.verification.to_s )


            start_tag( 'references' )
            issue.references.each{
                |name, url|
                add_reference( name, url )
            }
            end_tag( 'references' )


            add_variations( issue )

            end_tag( 'issue' )
        }

        end_tag( 'issues' )

        start_tag( 'plugins' )

        # get XML formatted plugin data and append them to the XML buffer
        format_plugin_results( @audit_store.plugins ).values.compact.each { |xml| append( xml ) }

        end_tag( 'plugins' )

        end_tag( 'arachni_report' )

        xml_write( )
        print_status( 'Saved in \'' + @outfile + '\'.' )
    end

    def xml_write( )
        file = File.new( @outfile, 'w' )
        file.write( @__buffer )
        file.close
    end


    def self.info
        {
            :name           => 'XML report',
            :description    => %q{Exports a report as an XML file.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.2',
            :options        => [
                Arachni::OptString.new( 'outfile', [ false, 'Where to save the report.',
                    Time.now.to_s + '.xml' ] ),
            ]
        }
    end

    def add_variations( issue )
        start_tag( 'variations' )
        issue.variations.each_with_index {
            |var|
            start_tag( 'variation' )

            simple_tag( 'url', var['url'] )
            simple_tag( 'id', URI.encode( var['id'] ) )
            simple_tag( 'injected', URI.encode( var['injected'] ) )
            simple_tag( 'regexp', var['regexp'].to_s )
            simple_tag( 'regexp_match', var['regexp_match'] )

            start_tag( 'headers' )

            if var['headers']['request'].is_a?( Hash )
                add_headers( 'request', var['headers']['request'] )
            end

            response = {}
            if var['headers']['response'].is_a?( Hash )
                response = var['headers']['response']
            else
                var['headers']['response'].split( "\r\n" ).each {
                    |line|
                    field, value = line.split( ':', 2 )
                    next if !value
                    response[field] = value
                }
            end

            if response.is_a?( Hash )
                add_headers( 'response', response )
            end

            end_tag( 'headers' )

            if !var['response'].empty? && var['response'] != '<n/a>'
                simple_tag( 'html', Base64.encode64( var['response'] ) )
            end

            end_tag( 'variation' )
        }
        end_tag( 'variations' )
    end

end
end
end
