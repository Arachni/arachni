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

#
# Should be extended/implemented by all HTML/HTTP modules.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
#
module Arachni::Element

module Capabilities
end

# load and include all available capabilities
lib = File.dirname( __FILE__ ) + '/capabilities/*.rb'
Dir.glob( lib ).each { |f| require f }

class Base
    include Capabilities::Auditable
    extend  Arachni::Utilities

    #
    # Relatively 'raw' (frozen) hash holding the element's HTML attributes, values, etc.
    #
    # @return  [Hash]
    #
    attr_reader :raw

    #
    # Initialize the element.
    #
    # @param    [String]  url     {#url}
    # @param    [Hash]    raw     {#raw}
    #
    def initialize( url, raw = {} )
        @raw = raw.dup
        @raw.freeze
        self.url = url.to_s

        @opts = {}
    end

    #
    # Must provide a string uniquely identifying self.
    #
    # @return  [String]
    #
    def id
        @raw.to_s
    end

    #
    # Must provide a simple hash representation of self
    #
    def simple
        {}
    end

    #
    # Method for the element.
    #
    # Should represent a method in {Arachni::Module::HTTP}.
    #
    # Ex. get, post, cookie, header
    #
    # @see Arachni::Module::HTTP
    #
    # @return [String]
    #
    def method
        @method.freeze
    end

    # @see #method
    def method=( method )
        @method = method
        rehash
        self.method
    end

    #
    # The url to which the element points and should be audited against.
    #
    # Ex. 'href' for links, 'action' for forms, etc.
    #
    # @return  [String]
    #
    def action
        @action.freeze
    end

    # @see #action
    def action=( url )
        @action = self.url ? to_absolute( url, self.url ) : normalize_url( url )
        rehash
        self.action
    end

    #
    # The URL of the page that owns the element.
    #
    # @return  [String]
    #
    def url
        @url.freeze
    end

    # @see #url
    def url=( url )
        @url = normalize_url( url )
        rehash
        self.url
    end

    #
    # Must provide the element type, one of {Arachni::Module::Auditor::Element}.
    #
    def type
        self.class.name.split( ':' ).last.downcase
    end

    def dup
        new = self.class.new( @url ? @url.dup : nil, @raw.dup )
        new.override_instance_scope if override_instance_scope?
        new.auditor   = self.auditor
        new.method    = self.method.dup
        new.altered   = self.altered.dup if self.altered
        new.auditable = self.auditable.dup
        new
    end

end
end
