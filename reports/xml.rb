=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'base64'


module Arachni
module Reports

#
# Creates an XML report of the audit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
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

        __start_tag( 'arachni_report' )

        __simple_tag( 'title', 'Web Application Security Report - Arachni Framework' )
        __simple_tag( 'generated_on', Time.now.to_s )
        __simple_tag( 'report_false_positives', REPORT_FP )

        __start_tag( 'system' )
        __simple_tag( 'version', @audit_store.version )
        __simple_tag( 'revision', @audit_store.revision )
        __simple_tag( 'start_datetime', @audit_store.start_datetime )
        __simple_tag( 'finish_datetime', @audit_store.finish_datetime )
        __simple_tag( 'delta_time', @audit_store.delta_time )

        __simple_tag( 'url', @audit_store.options['url'] )
        __simple_tag( 'user_agent', @audit_store.options['user_agent'] )

        __start_tag( 'audited_elements' )
        __simple_tag( 'element', 'links' ) if @audit_store.options['audit_links']
        __simple_tag( 'element', 'forms' ) if @audit_store.options['audit_forms']
        __simple_tag( 'element', 'cookies' ) if @audit_store.options['audit_cookies']
        __simple_tag( 'element', 'headers' ) if @audit_store.options['audit_headers']
        __end_tag( 'audited_elements' )

        __simple_tag( 'modules', @audit_store.options['mods'].join( ', ' ) )

        __start_tag( 'filters' )
        if @audit_store.options['exclude']
            __start_tag( "exclude" )
            @audit_store.options['exclude'].each {
                |ex|
                __simple_tag( 'filter', ex )
            }
            __end_tag( "exclude" )
        end

        if @audit_store.options['include']
            __start_tag( "include" )
            @audit_store.options['include'].each {
                |inc|
                __simple_tag( 'filter', inc )
            }
            __end_tag( "include" )
        end

        if @audit_store.options['redundant']
            __start_tag( "redundant" )
            @audit_store.options['redundant'].each {
                |red|
                __simple_tag( 'filter', red['regexp'] + ':' + red['count'].to_s )
            }
            __end_tag( "redundant" )
        end
        __end_tag( 'filters' )

        __start_tag( 'cookies' )
        if( @audit_store.options['cookies'] )
            @audit_store.options['cookies'].each {
                |cookie|
                __simple_tag( cookie[0], cookie[1] )
            }
        end
        __end_tag( 'cookies' )

        __end_tag( 'system' )

        __simple_tag( 'issue_cnt', @audit_store.issues.size.to_s )

        __start_tag( 'issues' )
        @audit_store.issues.each {
            |issue|

            __start_tag( 'issue' )
            __simple_tag( 'name', issue.name )

            __simple_tag( 'url', issue.url )
            __simple_tag( 'element', issue.elem )
            __simple_tag( 'variable', issue.var )
            __simple_tag( 'escription', issue.description )
            __simple_tag( 'manual_verification', issue.verification.to_s )

            __start_tag( 'references' )
            issue.references.each{
                |ref|
                __simple_tag( ref[0], ref[1] )
            }
            __end_tag( 'references' )

            __buffer_variations( issue )

            __end_tag( 'issue' )
        }

        __end_tag( 'issues' )

        __end_tag( 'arachni_report' )

        __xml_write( )

        print_status( 'Saved in \'' + @outfile + '\'.' )
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

    def __buffer_variations( issue )
        __start_tag( 'variations' )
        issue.variations.each_with_index {
            |var|
            __start_tag( 'variation' )

            __simple_tag( 'url', var['url'] )
            __simple_tag( 'id', var['id'] )
            __simple_tag( 'injected', var['injected'] )
            __simple_tag( 'regexp', var['regexp'].to_s )
            __simple_tag( 'regexp_match', var['regexp_match'] )

            __start_tag( 'headers' )
            __simple_tag( 'request', var['headers']['request'].to_s )
            __simple_tag( 'response', var['headers']['response'].to_s )
            __end_tag( 'headers' )

            __simple_tag( 'html', Base64.encode64( var['response'] ) )

            __end_tag( 'variation' )
        }
        __end_tag( 'variations' )
    end

    def __buffer( str = '' )
        @__buffer += str + "\n"
    end

    def __simple_tag( tag, text )
        __start_tag( tag )
        __add( text )
        __end_tag( tag )
    end

    def __start_tag( tag )
        __buffer( "<#{tag}>" )
    end

    def __add( text )
        # __buffer( "<![CDATA[#{text}]]>" )
        __buffer( "<![CDATA[#{URI.encode( text )}]]>" )
    end

    def __end_tag( tag )
        __buffer( "</#{tag}>" )
    end

    def __xml_write( )
        file = File.new( @outfile, 'w' )
        file.write( @__buffer )
        file.close
    end

end

end
end
