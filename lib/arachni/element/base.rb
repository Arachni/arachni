=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
module Arachni
module Element

module Capabilities
end

# load and include all available capabilities
lib = File.dirname( __FILE__ ) + '/capabilities/*.rb'
Dir.glob( lib ).each { |f| require f }

#
# Base class for all element types.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base
    include Capabilities::Auditable
    extend  Utilities

    # @return  [Hash]
    #   'raw' (frozen) hash holding the element's HTML attributes, values, etc.
    attr_reader :raw

    # @param    [String]  url     {#url}
    # @param    [Hash]    raw     {#raw}
    def initialize( url, raw = {} )
        @raw = raw.dup
        @raw.freeze
        self.url = url.to_s

        @opts = {}
    end

    # @return   [Platform]
    #   Applicable platforms for {#action} resource.
    def platforms
        Platform::Manager[@action]
    end

    # @return  [String] String uniquely identifying self.
    # @abstract
    def id
        @raw.to_s
    end

    # @return   [Hash] Simple representation of self.
    # @abstract
    def simple
        {}
    end

    # Should represent a method in {Arachni::Module::HTTP}.
    #
    # Ex. get, post, cookie, header
    #
    # @see Arachni::Module::HTTP
    #
    # @return [Symbol]  HTTP request method for the element.
    def method( *args )
        return super( *args ) if args.any?

        @method.freeze
    end

    # @see #method
    def method=( method )
        @method = method
        rehash
        self.method
    end

    # @note Ex. 'href' for links, 'action' for forms, etc.
    #
    # @return  [String]
    #   URI to which the element points and should be audited against.
    def action
        @action.freeze
    end

    # @see #action
    def action=( url )
        @action = self.url ? to_absolute( url, self.url ) : normalize_url( url )
        rehash
        self.action
    end

    # @return  [String]
    #   URL of the page that owns the element.
    def url
        @url.freeze
    end

    # @see #url
    def url=( url )
        @url = normalize_url( url )
        rehash
        self.url
    end

    # @return [String]  Element type.
    def type
        self.class.name.split( ':' ).last.downcase
    end

    def dup
        new = self.class.new( @url ? @url.dup : nil, @raw.dup )
        new.override_instance_scope if override_instance_scope?
        new.auditor   = self.auditor
        new.method    = self.method.dup
        new.altered   = self.altered.dup if self.altered
        new.format    = self.format
        new.auditable = self.auditable.dup
        new
    end

end
end
end
