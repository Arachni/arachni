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

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

HEADER = 'header'

class Header < Arachni::Element::Base

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

    # Overrides {Capabilities::Mutable#each_mutation} to handle header-specific
    # limitations.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( injection_str, opts = {}, &block )
        flip = opts.delete( :param_flip )
        super( injection_str, opts, &block )

        return if !flip
        elem = self.dup

        # when under HPG mode element auditing is strictly regulated
        # and when we flip params we essentially create a new element
        # which won't be on the whitelist
        elem.override_instance_scope

        elem.altered = 'Parameter flip'
        elem.auditable = { injection_str => seed }
        yield elem
    end

    # @return   [String]    Header name.
    def name
        @auditable.first.first
    end

    # @return   [String]    Header value.
    def value
        @auditable.first.last
    end

    def type
        Arachni::Element::HEADER
    end

    def self.encode( header )
        ::URI.encode( header, "\r\n" )
    end
    def encode( header )
        self.class.encode( header )
    end

    def self.decode( header )
        ::URI.decode( header )
    end
    def decode( header )
        self.class.decode( header )
    end


    private
    def http_request( opts, &block )
        http.header( @action, opts, &block )
    end

end
end

Arachni::Header = Arachni::Element::Header
