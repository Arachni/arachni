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

class Arachni::Parser::Element::Cookie < Arachni::Parser::Element::Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @url
        @method = 'cookie'

        if @raw['name'] && @raw['value']
            @auditable = { @raw['name'] => @raw['value'] }
        else
            @auditable = raw.dup
            @raw = {
                'name'  => @auditable.keys.first,
                'value' => @auditable.values.first
            }
        end

        @simple = @auditable.dup
        @auditable.reject! {
            |cookie|
            Arachni::Options.instance.exclude_cookies.include?( cookie )
        }

        @orig = @auditable.deep_clone
        @orig.freeze
    end

    def name
        simple.keys.first
    end

    def value
        simple.values.first
    end

    def secure?
        @raw['secure'] == true
    end

    def http_only?
        @raw['httponly'] == true
    end

    def simple
        @simple
    end

    def type
        Arachni::Module::Auditor::Element::COOKIE
    end

    private
    def http_request( opts = {} )
        http.cookie( @action, opts || {} )
    end

end
