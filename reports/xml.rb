=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'base64'
require 'cgi'

module Arachni
module Reports

#
# Creates an XML report of the audit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class XML < Arachni::Report::Base

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

        add_plugin_results

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
            :author         => 'zapotek',
            :version        => '0.1',
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


    def add_plugin_results
        return if @audit_store.plugins.empty?

        start_tag( 'plugins' )

        print_cookie_collector
        print_form_dicattack
        print_http_dicattack
        print_healthmap
        print_content_types

        end_tag( 'plugins' )
    end

    def print_healthmap
        healthmap = @audit_store.plugins['healthmap']
        return if !healthmap || healthmap[:results].empty?

        start_tag( 'healthmap' )
        simple_tag( 'description', healthmap[:description] )

        start_tag( 'results' )
        start_tag( 'map' )
        healthmap[:results][:map].each {
            |i|

            state = i.keys[0]
            url   = i.values[0]

            if state == :unsafe
                add_url( 'unsafe', url )
            else
                add_url( 'safe', url )
            end
        }
        end_tag( 'map' )

        start_tag( 'stats' )

        simple_tag( 'total', healthmap[:results][:total].to_s )
        simple_tag( 'safe', healthmap[:results][:safe].to_s )
        simple_tag( 'unsafe', healthmap[:results][:unsafe].to_s )
        simple_tag( 'issue_percentage', healthmap[:results][:issue_percentage].to_s )

        end_tag( 'stats' )
        end_tag( 'results' )
        end_tag( 'healthmap' )
    end

    def print_cookie_collector
        cookie_collector = @audit_store.plugins['cookie_collector']
        return if !cookie_collector || cookie_collector[:results].empty?

        start_tag( 'cookie_collector' )
        simple_tag( 'description', cookie_collector[:description] )

        start_tag( 'results' )
        cookie_collector[:results].each_with_index {
            |result, i|

            start_tag( 'response' )
            simple_tag( 'time', result[:time].to_s )
            simple_tag( 'url', result[:res]['effective_url'] )

            start_tag( 'cookies' )
            result[:cookies].each_pair{
                |name, value|
                add_cookie( name, value )
            }
            end_tag( 'cookies' )
            end_tag( 'response' )
        }
        end_tag( 'results' )

        end_tag( 'cookie_collector' )
    end

    def print_form_dicattack
        form_dicattack = @audit_store.plugins['form_dicattack']
        return if !form_dicattack || form_dicattack[:results].empty?

        start_tag( 'form_dicattack' )
        simple_tag( 'description', form_dicattack[:description] )

        start_tag( 'results' )

        add_credentials( form_dicattack[:results][:username],
            form_dicattack[:results][:password] )

        end_tag( 'results' )
        end_tag( 'form_dicattack' )
    end

    def print_http_dicattack
        http_dicattack = @audit_store.plugins['http_dicattack']
        return if !http_dicattack || http_dicattack[:results].empty?

        start_tag( 'http_dicattack' )
        simple_tag( 'description', http_dicattack[:description] )

        start_tag( 'results' )

        add_credentials( http_dicattack[:results][:username],
            http_dicattack[:results][:password] )

        end_tag( 'results' )
        end_tag( 'http_dicattack' )
    end

    def print_content_types
        content_types = @audit_store.plugins['content_types']
        return if !content_types || content_types[:results].empty?

        start_tag( 'content_types' )
        simple_tag( 'description', content_types[:description] )

        start_tag( 'results' )
        content_types[:results].each_pair {
            |type, responses|

            start_content_type( type )

            responses.each {
                |res|

                start_tag( 'response' )

                simple_tag( 'url', res[:url] )
                simple_tag( 'method', res[:method] )

                if res[:params] && res[:method].downcase == 'post'
                    start_tag( 'params' )
                    res[:params].each_pair {
                        |name, value|
                        add_param( name, value )
                    }
                    end_tag( 'params' )
                end

                end_tag( 'response' )
            }

            end_content_type
        }

        end_tag( 'results' )
        end_tag( 'content_types' )
    end


    def simple_tag( tag, text, no_escape = false )
        start_tag( tag )
        __add( text, no_escape )
        end_tag( tag )
    end

    def add_reference( name, url )
        __buffer( "<reference name=\"#{name}\" url=\"#{url}\" />" )
    end

    def add_cookie( name, value )
        __buffer( "<cookie name=\"#{name}\" value=\"#{value}\" />" )
    end

    def add_param( name, value )
        __buffer( "<param name=\"#{name}\" value=\"#{value}\" />" )
    end

    def start_content_type( type )
        __buffer( "<content_type name=\"#{type}\">" )
    end

    def end_content_type
        __buffer( "</content_type>" )
    end

    def add_mod( name )
        __buffer( "<module name=\"#{name}\" />" )
    end

    def add_headers( type, headers )

        start_tag( type )
        headers.each_pair {
            |name, value|
            __buffer( "<field name=\"#{name}\" value=\"#{CGI.escapeHTML( value.strip )}\" />" )
        }
        end_tag( type )
    end

    def add_url( type, url )
        __buffer( "<entry state=\"#{type}\" url=\"#{url}\" />" )
    end

    def add_credentials( username, password )
        __buffer( "<credentials username=\"#{username}\" password=\"#{password}\" />" )
    end

    def start_tag( tag )
        __buffer( "\n<#{tag}>" )
    end

    def end_tag( tag )
        __buffer( "</#{tag}>\n" )
    end


    def __buffer( str = '' )
        @__buffer += str
    end

    def __add( text, no_escape = false )
        if !no_escape
            __buffer( CGI.escapeHTML( text ) )
        else
            __buffer( text )
        end
    end

end
end
end
