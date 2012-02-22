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

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/element/base'

class Arachni::Parser::Element::Form < Arachni::Parser::Element::Base

    include Arachni::Module::Utilities

    FORM_VALUES_ORIGINAL  = '__original_values__'
    FORM_VALUES_SAMPLE    = '__sample_values__'

    def initialize( url, raw = {} )
        super( url, raw )

        begin
            @action = @raw['action'] || @raw[:action] || @raw['attrs']['action']
        rescue
            @action = url
        end

        begin
            @method = @raw['method'] || @raw[:method] || @raw['attrs']['method']
        rescue
            @method = 'post'
        end

        @auditable = @raw[:inputs] || @raw['inputs'] || simple['auditable'] || {}
        @orig      = @auditable.deep_clone
        @orig.freeze
    end

    def id
        id = simple['attrs'].to_s

        auditable.each {
            |name, value|
            next if name.substring?( seed )
            id +=  name
        }

        return id
    end

    def simple
        form = {}

        if @raw['attrs']
            form['attrs'] = @raw['attrs']
            form['auditable'] = {}
            if @raw['auditable'] && !@raw['auditable'].empty?
                @raw['auditable'].each {
                    |item|
                    if( !item['name'] ) then next end
                    form['auditable'][item['name']] = item['value']
                }
            end
        else
            form = {
                'attrs' => {
                    'method' => @method,
                    'action' => @action
                },
                'auditable' => @auditable
            }
        end

        form['auditable'] ||= {}
        form.dup
    end

    def type
        Arachni::Module::Auditor::Element::FORM
    end

    private
    def http_request( opts )
        params   = opts[:params]
        altered  = opts[:altered]

        curr_opts = opts.dup
        if( altered == FORM_VALUES_ORIGINAL )
            orig_id = audit_id( FORM_VALUES_ORIGINAL )

            return if !opts[:redundant] && audited?( orig_id )
            audited!( orig_id )

            print_debug( 'Submitting form with original values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end

        if( altered == FORM_VALUES_SAMPLE )
            sample_id = audit_id( FORM_VALUES_SAMPLE )

            return if !opts[:redundant] && audited?( sample_id )
            audited!( sample_id )

            print_debug( 'Submitting form with sample values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end


        @method.downcase.to_s != 'get' ? http.post( @action, opts ) : http.get( @action, opts )
    end

end
