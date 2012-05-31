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
require opts.dir['lib'] + 'parser/element/mutable'
require opts.dir['lib'] + 'parser/element/auditable'

#
# Should be extended/implemented by all HTML/HTTP modules.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
#
class Arachni::Parser::Element::Base
    include Arachni::Parser::Element::Auditable

    #
    # The URL of the page that owns the element.
    #
    # @return  [String]
    #
    attr_accessor :url

    #
    # The url to which the element points and should be audited against.
    #
    # Ex. 'href' for links, 'action' for forms, etc.
    #
    # @return  [String]
    #
    attr_accessor :action

    #
    # Relatively 'raw' hash holding the element's HTML attributes, values, etc.
    #
    # @return  [Hash]
    #
    attr_accessor :raw

    #
    # Method of the element.
    #
    # Should represent a method in {Arachni::Module::HTTP}.
    #
    # Ex. get, post, cookie, header
    #
    # @see Arachni::Module::HTTP
    #
    # @return [String]
    #
    attr_accessor :method

    #
    # Initialize the element.
    #
    # @param    [String]  url     {#url}
    # @param    [Hash]    raw     {#raw}
    #
    def initialize( url, raw = {} )
        @raw = raw.dup
        @url = normalize_url( url.to_s )

        @opts = {}
    end

    def skip?( elem )
        if Arachni::Options.instance.exclude_vectors.include?( elem.altered )
            auditor.print_info "Skipping audit of '#{elem.altered}' #{type} vector."
            return true
        end
        super( elem )
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

    def ==( e )
        hash == e.hash
    end
    alias :eql? :==

    def hash
        (@action.to_s + @method + @auditable.to_s).hash
    end

    #
    # Must provide the element type, one of {Arachni::Module::Auditor::Element}.
    #
    def type
        self.class.name.split( ':' ).last.downcase
    end

    def dup
        new = self.class.new( @url ? @url.dup : nil, @raw.deep_clone )
        new.override_instance_scope if override_instance_scope?
        new
    end

end
