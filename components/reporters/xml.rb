=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'nokogiri'

# Creates an XML report of the audit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Reporters::XML < Arachni::Reporter::Base

    LOCAL_SCHEMA  = File.dirname( __FILE__ ) + '/xml/schema.xsd'
    REMOTE_SCHEMA = 'https://raw.githubusercontent.com/Arachni/arachni/' <<
        "v#{Arachni::VERSION}/components/reporters/xml/schema.xsd"
    NULL          = '[ARACHNI_NULL]'

    def run
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.report(
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:noNamespaceSchemaLocation' => REMOTE_SCHEMA
            ) {
                xml.version report.version
                xml.seed report.seed
                xml.options Arachni::Options.hash_to_save_data( report.options )
                xml.start_datetime report.start_datetime.xmlschema
                xml.finish_datetime report.finish_datetime.xmlschema

                xml.sitemap {
                    report.sitemap.each do |url, code|
                        xml.entry url: replace_nulls( url ), code: code
                    end
                }

                xml.issues {
                    report.issues.each do |issue|
                        xml.issue {
                            xml.name issue.name
                            xml.description issue.description
                            xml.remedy_guidance issue.remedy_guidance
                            xml.remedy_code issue.remedy_code
                            xml.severity issue.severity

                            xml.check {
                                %w(name description author version shortname).each do |attr|
                                    xml.send( attr, issue.check[attr.to_sym] )
                                end
                            }

                            if issue.cwe
                                xml.cwe issue.cwe
                            end

                            xml.digest issue.digest

                            xml.references {
                                issue.references.each do |title, url|
                                    xml.reference title: title, url: url
                                end
                            }

                            vector = issue.vector
                            xml.vector {
                                xml.class_ vector.class
                                xml.type vector.type
                                xml.url replace_nulls( vector.url )
                                xml.action replace_nulls( vector.action )

                                if vector.respond_to? :source
                                    xml.source replace_nulls( vector.source )
                                end

                                if vector.respond_to? :seed
                                    xml.seed replace_nulls( vector.seed )
                                end

                                if issue.active?
                                    xml.method_ vector.method
                                end

                                if vector.respond_to? :affected_input_name
                                    xml.affected_input_name replace_nulls( vector.affected_input_name )
                                end

                                if vector.respond_to? :inputs
                                    add_inputs( xml, vector.inputs )
                                end

                                if vector.respond_to? :default_inputs
                                    add_inputs( xml, vector.default_inputs, :default_inputs  )
                                end
                            }

                            xml.remarks {
                                issue.remarks.each do |commenter, remarks|
                                    remarks.each do |remark|
                                        xml.remark {
                                            xml.commenter commenter
                                            xml.text_ remark
                                        }
                                    end
                                end
                            }

                            add_page( xml, issue.page )
                            add_page( xml, issue.referring_page, :referring_page )

                            xml.signature issue.signature
                            xml.proof issue.proof
                            xml.trusted issue.trusted
                            xml.platform_type issue.platform_type
                            xml.platform_name issue.platform_name
                        }
                    end
                }

                xml.plugins {
                    format_plugin_results( false ) do |name, formatter|
                        xml.send( "#{name}_" ) {
                            xml.name report.plugins[name][:name]
                            xml.description report.plugins[name][:description]

                            xml.results { formatter.run xml }
                        }
                    end
                }
            }
        end

        xml = builder.to_xml

        xsd = Nokogiri::XML::Schema( IO.read( LOCAL_SCHEMA ) )
        has_errors = false
        xsd.validate( Nokogiri::XML( xml ) ).each do |error|
            puts error.message
            puts " -- Line #{error.line}, column #{error.column}, level #{error.level}."
            puts '-' * 100

            justify = (error.line+10).to_s.size
            lines = xml.lines
            ((error.line-10)..(error.line+10)).each do |i|
                line = lines[i]
                next if i < 0 || !line
                i = i + 1

                printf( "%#{justify}s | %s", i, line )

                if i == error.line
                    printf( "%#{justify}s |", i )
                    line.size.times.each do |c|
                        print error.column == c ? '^' : '-'
                    end
                    puts
                end
            end

            puts '-' * 100
            puts

            has_errors = true
        end

        if has_errors
            print_error 'Report could not be validated against the XSD due to the above errors.'
            return
        end

        IO.binwrite( outfile, xml )

        print_info "Null bytes have been replaced with: #{NULL}"
        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:         'XML',
            description:  %q{Exports the audit results as an XML (.xml) file.},
            content_type: 'text/xml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:      '0.3.6',
            options:      [ Options.outfile( '.xml' ), Options.skip_responses ]
        }
    end

    def self.replace_nulls( s )
        s.to_s.gsub( "\0", NULL )
    end

    def replace_nulls( *args )
        self.class.replace_nulls( *args )
    end

    def add_inputs( xml, inputs, name = :inputs )
        xml.send( name ) {
            inputs.each do |k, v|
                xml.input( name: replace_nulls( k ), value: replace_nulls( v ) )
            end
        }
    end

    def add_headers( xml, headers )
        xml.headers {
            headers.each do |k, v|
                xml.header( name: replace_nulls( k ), value: replace_nulls( v ) )
            end
        }
    end

    def add_parameters( xml, parameters )
        xml.parameters {
            parameters.each do |k, v|
                xml.parameter( name: replace_nulls( k ), value: replace_nulls( v ) )
            end
        }
    end

    def add_page( xml, page, name = :page )
        xml.send( name ) {
            xml.body replace_nulls( page.body )

            request = page.request
            xml.request {
                xml.url replace_nulls( request.url )
                xml.method_ request.method

                add_parameters( xml, request.parameters )
                add_headers( xml, request.headers )

                xml.body replace_nulls( request.effective_body )
                xml.raw replace_nulls( request )
            }

            response = page.response
            xml.response {
                xml.url replace_nulls( response.url )
                xml.code response.code
                xml.ip_address response.ip_address
                xml.time response.time.round( 4 )
                xml.return_code response.return_code
                xml.return_message response.return_message

                add_headers( xml, response.headers )

                xml.body replace_nulls( response.body )
                xml.raw_headers replace_nulls( response.headers_string )
            }

            dom = page.dom
            xml.dom {
                xml.url replace_nulls( dom.url )

                xml.transitions {
                    dom.transitions.each do |transition|
                        xml.transition {
                            xml.element transition.element
                            xml.event transition.event
                            xml.time transition.time.to_f.round( 4 )
                        }
                    end
                }

                xml.data_flow_sinks {
                    dom.data_flow_sinks.each do |sink|
                        xml.data_flow_sink {
                            xml.object sink.object
                            xml.tainted_argument_index sink.tainted_argument_index
                            xml.tainted_value replace_nulls( sink.tainted_value )
                            xml.taint_ replace_nulls( sink.taint )

                            add_function( xml, sink.function )
                            add_trace( xml, sink.trace )
                        }
                    end
                }

                xml.execution_flow_sinks {
                    dom.execution_flow_sinks.each do |sink|
                        xml.execution_flow_sink {
                            add_trace( xml, sink.trace )
                        }
                    end
                }
            }
        }
    end

    def add_trace( xml, trace )
        xml.trace {
            trace.each do |frame|
                xml.frame {
                    add_function( xml, frame.function )
                    line = xml.line( frame.line )

                    if frame.line.nil?
                        line['xsi:nil'] = true
                    end

                    xml.url frame.url
                }
            end
        }
    end

    def add_function( xml, function )
        xml.function {
            xml.name function.name
            xml.source function.source
            xml.arguments {
                if function.arguments
                    function.arguments.each do |argument|
                        xml.argument argument.inspect
                    end
                end
            }
        }
    end

end
