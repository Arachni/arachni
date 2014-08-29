=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'nokogiri'

# Creates an XML report of the audit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.3
class Arachni::Reporters::XML < Arachni::Reporter::Base

    LOCAL_SCHEMA  = File.dirname( __FILE__ ) + '/xml/schema.xsd'
    REMOTE_SCHEMA = 'https://raw.githubusercontent.com/Arachni/arachni/' <<
        "v#{Arachni::VERSION}/components/reporters/xml/schema.xsd"

    def run
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.report(
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:noNamespaceSchemaLocation' => REMOTE_SCHEMA
            ) {
                xml.version report.version
                xml.options Arachni::Options.hash_to_save_data( report.options )
                xml.start_datetime report.start_datetime.xmlschema
                xml.finish_datetime report.finish_datetime.xmlschema

                xml.sitemap {
                    report.sitemap.each do |url, code|
                        xml.entry url: url, code: code
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
                                xml.url vector.url
                                xml.action vector.action

                                if vector.respond_to? :html
                                    xml.html vector.html
                                end

                                if issue.active?
                                    xml.method_ vector.method
                                end

                                if vector.respond_to? :affected_input_name
                                    xml.affected_input_name vector.affected_input_name
                                end

                                if vector.respond_to? :inputs
                                    add_inputs( xml, vector.inputs )
                                end
                            }

                            xml.variations {
                                issue.variations.each do |variation|
                                    xml.variation {
                                        vector = variation.vector

                                        xml.vector {
                                            if issue.active?
                                                xml.method_ vector.method
                                            end

                                            if vector.respond_to? :seed
                                                xml.seed vector.seed
                                            end

                                            if vector.respond_to? :inputs
                                                add_inputs( xml, vector.inputs )
                                            end
                                        }

                                        xml.remarks {
                                            variation.remarks.each do |commenter, remarks|
                                                xml.commenter commenter
                                                remarks.each do |remark|
                                                    xml.remark remark
                                                end
                                            end
                                        }

                                        add_page( xml, variation.page )
                                        add_page( xml, variation.referring_page, :referring_page )

                                        xml.signature variation.signature
                                        xml.proof variation.proof
                                        xml.trusted variation.trusted
                                        xml.platform_type variation.platform_type
                                        xml.platform_name variation.platform_name
                                    }
                                end
                            }
                        }
                    end
                }

                xml.plugins {
                    format_plugin_results( false ) do |name, formatter|
                        xml.send( name ) {
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
            ap error
            has_errors = true
        end
        fail 'XML report could not be validated against the XSD.' if has_errors

        IO.binwrite( outfile, xml )
        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:         'XML',
            description:  %q{Exports the audit results as an XML (.xml) file.},
            content_type: 'text/xml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:      '0.3',
            options:      [ Options.outfile( '.xml' ), Options.skip_responses ]
        }
    end

    def add_inputs( xml, inputs, name = :inputs )
        xml.send( name ) {
            inputs.each do |k, v|
                xml.input( name: k, value: v )
            end
        }
    end

    def add_headers( xml, headers )
        xml.headers {
            headers.each do |k, v|
                xml.header( name: k, value: v )
            end
        }
    end

    def add_parameters( xml, parameters )
        xml.parameters {
            parameters.each do |k, v|
                xml.parameter( name: k, value: v )
            end
        }
    end

    def add_page( xml, page, name = :page )
        xml.send( name ) {
            xml.body page.body

            request = page.request
            xml.request {
                xml.url request.url
                xml.method_ request.method

                add_parameters( xml, request.parameters )
                add_headers( xml, request.headers )

                xml.body request.effective_body
                xml.raw request.to_s
            }

            response = page.response
            xml.response {
                xml.url response.url
                xml.code response.code
                xml.ip_address response.ip_address
                xml.time response.time.round( 4 )
                xml.return_code response.return_code
                xml.return_message response.return_message

                add_headers( xml, response.headers )

                xml.body response.body
                xml.raw_headers response.headers_string
            }

            dom = page.dom
            xml.dom {
                xml.url dom.url

                xml.transitions {
                    dom.transitions.each do |transition|
                        xml.transition {
                            xml.element transition.element
                            xml.event transition.event
                            xml.time transition.time.round( 4 )
                        }
                    end
                }

                xml.data_flow_sinks {
                    dom.data_flow_sinks.each do |sink|
                        xml.data_flow_sink {
                            xml.object sink.object
                            xml.tainted_argument_index sink.tainted_argument_index
                            xml.tainted_value sink.tainted_value
                            xml.taint_ sink.taint

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
                    xml.line frame.line
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
