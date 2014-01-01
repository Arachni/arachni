=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Profiler plugin.
#
# Examines the behavior of the web application gathering general statistics
# and performs taint analysis to determine which inputs affect the output.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
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
    class Auditor < Module::Base

        def seed_id
            @seed_id ||= Digest::SHA2.hexdigest( rand( 1000 ).to_s )
        end

        def run( &logger )
            audit( seed_id, format: [Format::APPEND] ) do |res, _, elem|
                landed_elems = []

                if res.body.include?( seed_id )
                    landed_elems |= find_landing_elements( res )
                end

                if res.headers.to_s.include?( seed_id )
                    landed_elems |= find_landing_header_fields( res )
                end

                logger.call( seed_id, res, elem, landed_elems ) if landed_elems.any?
            end
        end

        def find_landing_header_fields( res )
            elems = []

            parser = Parser.new( res )
            parser.cookies.each do |cookie|
                elems << cookie if cookie.auditable.to_s.substring?( seed_id )
            end

            res.headers_hash.each_pair do |k, v|
                next if !v.to_s.substring?( seed_id )
                elems << Header.new( res.effective_url, { k => v.to_s } )
            end

            elems
        end

        def find_landing_elements( res )
            elems = []
            elems << Struct::Body.new( 'body', nil, { 'attrs' => {} } )

            parser = Parser.new( res )
            parser.forms.each do |form|
                elems << form if form.auditable.to_s.substring?( seed_id )
            end

            self_url = Link.new( res.effective_url )
            parser.links.each do |link|
                if link.auditable.to_s.substring?( seed_id )
                    # skip ourselves
                    next if link.auditable == self_url.auditable
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
        Struct.new( 'Body', :type, :method, :raw, :auditable )

        @inputs = []
    end

    def run
        framework.on_audit_page do |page|
            Auditor.new( page, framework ).run do |taint, res, elem, found_in|
                log( taint, res, elem, found_in )
            end
        end
    end

    def clean_up
        wait_while_framework_running
        register_results( @inputs )
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
                'params'   => res.request.params || {},
                'headers'  => res.request.headers,
            }
        }

        result['landed'] = landed_elems.map do |elem|
            {
                'type'   => elem.type,
                'method' => elem.method ? elem.method.upcase : nil,
                'name'   => elem.raw['attrs'] ? elem.raw['attrs']['name'] : nil,
                'auditable' => elem.auditable
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
            version:     '0.1.5'
        }
    end

end
