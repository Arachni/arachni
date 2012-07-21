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

require Arachni::Options.instance.dir['lib'] + 'parser/element/base'

class Arachni::Parser::Element::Header < Arachni::Parser::Element::Base

    def initialize( url, raw = {} )
        super( url, raw )

        self.action    = @url
        self.method    = 'get'
        self.auditable = @raw

        @orig = self.auditable.dup
        @orig.freeze
    end

    def simple
        @auditable.dup
    end

    def mutations( injection_str, opts = {} )
        flip = opts.delete( :param_flip )
        muts = super( injection_str, opts )

        if flip
            elem = self.dup

            # when under HPG mode element auditing is strictly regulated
            # and when we flip params we essentially create a new element
            # which won't be on the whitelist
            elem.override_instance_scope

            elem.altered = 'Parameter flip'
            elem.auditable = { injection_str => seed }
            muts << elem
        end

        muts
    end

    def type
        Arachni::Module::Auditor::Element::HEADER
    end

    private
    def http_request( opts, &block )
        http.header( @action, opts, &block )
    end

end
