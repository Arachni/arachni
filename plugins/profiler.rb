=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Profiler plugin.
#
# Examines the behavior of the web application gathering general statistics
# and performs taint analysis to determine which inputs affect the output.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Profiler < Arachni::Plugin::Base

    #
    # Assumes the identity of an Auditor.
    #
    # It will audit all inputs and log when inserted values appear in a page's body.<br/>
    # It's does not perform any vulnerability assesment nor does it send attack payloads,
    # just simple benign strings.
    #
    # Since an Auditor has formal specifications a plug-in can't directly become one
    # due to it's abstract nature.
    #
    # Thus, we use this helper class to perform auditing duties.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Auditor < Arachni::Module::Base

        attr_reader :http
        attr_reader :page

        def initialize( page )
            super( page )

            @id = Digest::SHA2.hexdigest( rand( 1000 ).to_s )
            @opts = {
                :format    => [ Format::STRAIGHT ],
                :elements  => [
                    Issue::Element::FORM,
                    Issue::Element::LINK,
                    Issue::Element::COOKIE,
                    Issue::Element::HEADER
                ],
                :remove_id => true
            }

            @@logged ||= Set.new
        end

        def run( &logger )
            audit( @id, @opts ) {
                |res, opts, elem|

                landed_elems = []
                if res.body.substring?( @id )
                    landed_elems |= find_landing_elements( res )
                end

                if res.headers.to_s.substring?( @id )
                    landed_elems |= find_landing_header_fields( res )
                end

                if !landed_elems.empty?

                    @@logged << "#{elem.action}::#{elem.altered}::#{elem.type}"

                    logger.call( @id, res, elem, landed_elems )
                end

            }
        end

        def find_landing_header_fields( res )
            elems = []

            parser = Arachni::Parser.new( Arachni::Options.instance, res )
            parser.cookies.each {
                |cookie|
                elems << cookie if cookie.auditable.to_s.substring?( @id )
            }

            res.headers_hash.each_pair {
                |k, v|
                elems << Arachni::Parser::Element::Header.new( res.effective_url, { k => v } ) if v.substring?( @id )
            }

            return elems
        end

        def find_landing_elements( res )
            elems = []

            elems << Struct::Body.new( 'body', nil, { 'attrs' => {} } )

            parser = Arachni::Parser.new( Arachni::Options.instance, res )
            parser.forms.each {
                |form|
                elems << form if form.auditable.to_s.substring?( @id )
            }

            parser.links.each {
                |link|
                elems << link if link.auditable.to_s.substring?( @id )
            }

            return elems
        end

        def skip?( elem )
            @@logged.include?( "#{elem.action}::#{elem.altered}::#{elem.type}" )
        end

        def self.info
            { :name => 'Profiler' }
        end

    end

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @http      = framework.http
        @options   = options
    end

    def prepare

        Struct.new( 'Body', :type, :method, :raw, :auditable )

        @inputs = []
        @times  = []
    end

    def run

        @http.add_on_complete {
            |res|
            @times << {
                'url'    => res.effective_url,
                'method' => res.request.method.to_s.upcase,
                'params' => res.request.params,
                'time'   => res.start_transfer_time
            }
        }

        @framework.add_on_run_mods {
            |page|

            Auditor.new( page ).run {
                |taint, res, elem, found_in|
                log( taint, res, elem, found_in )
            }

        }
    end

    def clean_up
        ::IO.select( nil, nil, nil, 1 ) while( @framework.running? )

        register_results( { 'inputs' => @inputs, 'times' => @times } )
    end

    def log( taint, res, elem, landed_elems )

        res_hash = res.to_hash
        res_hash['headers'] = res_hash['headers_hash']

         result = {
            'taint'       => taint,
            'element'     =>  {
                'type'      => elem.type,
                'auditable' => elem.auditable,
                'name'      => elem.raw['attrs'] ? elem.raw['attrs']['name'] : nil,
                'altered'   => elem.altered,
                'owner'     => elem.url,
                'action'    => elem.action,
                'method'    => elem.method ? elem.method.upcase : nil,
            },
            'response'      => res_hash,
            'request' => {
                'url'      => res.request.url,
                'method'   => res.request.method.to_s.upcase,
                'params'   => res.request.params,
                'headers'  => res.request.headers,
            }
        }

        result['landed'] = landed_elems.map {
            |elem|
            {
                'type'   => elem.type,
                'method' => elem.method ? elem.method.upcase : nil,
                'name'   => elem.raw['attrs'] ? elem.raw['attrs']['name'] : nil,
                'auditable' => elem.auditable
            }
        }

        @inputs << result
    end

    def self.distributable?
        true
    end

    def self.merge( results )
        inputs = []
        times = []

        results.each {
            |result|
            inputs |= result['inputs']
            times |= result['times']
        }

        return { 'inputs' => inputs, 'times' => times }
    end

    def self.info
        {
            :name           => 'Profiler',
            :description    => %q{Examines the behavior of the web application gathering general statistics
                and performs taint analysis to determine which inputs affect the output.

                It does not perform any vulnerability assesment nor does it send attack payloads.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1'
        }
    end

end

end
end
