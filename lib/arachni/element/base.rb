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

    def initialize( options )
        options = options.symbolize_keys( false )

        if !(options[:url] || options[:action])
            fail 'Needs :url or :action option.'
        end

        super

        @initialised_options = options.deep_clone

        self.url    = options[:url]    || options[:action]
        self.action = options[:action] || self.url
    end

    # @return   [Platform]
    #   Applicable platforms for {#action} resource.
    def platforms
        Platform::Manager[@action]
    end

    # @return  [String] String uniquely identifying self.
    # @abstract
    def id
        "#{action}:#{method}:#{inputs}"
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
        @method = method.to_s.downcase.to_sym
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
        new = self.class.new( @initialised_options )
        new.override_instance_scope if override_instance_scope?
        new.auditor = self.auditor
        new.method  = self.method
        new.altered = self.altered.dup if self.altered
        new.format  = self.format
        new.audit_options  = self.audit_options.dup
        new.inputs  = self.inputs.dup
        new
    end

end
end
end
