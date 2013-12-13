=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Profiler plugin.
#
# Examines the behavior of the web application gathering general statistics
# and performs taint analysis to determine which inputs affect the output.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Plugins::Profiler < Arachni::Plugin::Base

    is_distributable

    #
    # Assumes the identity of an Auditor.
    #
    # It will audit all inputs and log when inserted values appear in a page's body.
    #
    # It does not perform any vulnerability assessment nor does it send attack payloads,
    # just simple benign strings.
    #
    # Since an Auditor has formal specifications a plug-in can't directly become one
    # due to it's abstract nature, we use this helper class to perform the auditing duties.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Auditor < Check::Base

        def seed_id
            @seed_id ||= Digest::SHA2.hexdigest( rand( 1000 ).to_s )
        end

        def run( &logger )
            audit( seed_id, format: [Format::APPEND] ) do |res|
                landed_elems = []

                if res.body.include?( seed_id )
                    landed_elems |= find_landing_elements( res )
                end

                if res.headers.to_s.include?( seed_id )
                    landed_elems |= find_landing_header_fields( res )
                end

                logger.call( seed_id, res, landed_elems ) if landed_elems.any?
            end
        end

        def find_landing_header_fields( res )
            elems = []

            parser = Parser.new( res )
            parser.cookies.each do |cookie|
                elems << cookie if cookie.inputs.to_s.substring?( seed_id )
            end

            res.headers.each_pair do |k, v|
                next if !v.to_s.substring?( seed_id )
                elems << Header.new( url: res.url, inputs: { k => v.to_s } )
            end

            elems
        end

        def find_landing_elements( res )
            elems = []
            elems << Struct::Body.new( 'body', nil, {} )

            parser = Parser.new( res )
            parser.forms.each do |form|
                elems << form if form.inputs.to_s.substring?( seed_id )
            end

            self_url = Link.new( url: res.url )
            parser.links.each do |link|
                if link.inputs.to_s.substring?( seed_id )
                    # skip ourselves
                    next if link.inputs == self_url.inputs
                    elems << link
                end
            end

            elems
        end

        def self.info
            { name: 'Profiler' }
        end

    end

    def prepare
        Struct.new( 'Body', :type, :method, :inputs )

        @inputs = []
    end

    def run
        framework.on_audit_page do |page|
            Auditor.new( page, framework ).run do |taint, res, found_in|
                log( taint, res, found_in )
            end
        end
    end

    def clean_up
        wait_while_framework_running
        register_results( @inputs )
    end

    def log( taint, res, landed_elems )
        elem = res.request.performer

        res_hash = res.to_h.stringify_keys
        res_hash['headers'] = {}.merge( res_hash['headers'] )

        result = {
            'taint'       => taint,
            'element'     =>  {
                'type'                => elem.type.to_s,
                'auditable'           => elem.inputs,
                'name'                => elem.is_a?( Form ) ? elem.name_or_id : nil,
                'affected_input_name' => elem.affected_input_name,
                'owner'               => elem.url,
                'action'              => elem.action,
                'method'              => elem.method ? elem.method.upcase : nil,
            },
            'response'      => res_hash,
            'request' => {
                'url'      => res.request.url,
                'method'   => res.request.method.to_s.upcase,
                'params'   => res.request.parameters || {},
                'headers'  => res.request.headers,
            }
        }

        result['landed'] = landed_elems.map do |elem|
            {
                'type'      => elem.type.to_s,
                'method'    => elem.method.to_s.upcase,
                'name'      => elem.is_a?( Form ) ? elem.name_or_id : nil,
                'auditable' => elem.inputs
            }
        end

        @inputs << result
    end

    def self.merge( results )
        results.flatten
    end

    def self.info
        {
            name:        'Profiler',
            description: %q{Examines the behavior of the web application gathering general statistics
                and performs taint analysis to determine which inputs affect the output.

                It does not perform any vulnerability assessment nor does it send attack payloads.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6'
        }
    end

end
