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

module Arachni

class Page

# Static DOM snapshot as computed by a real browser.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM

    IGNORE_FROM_HASH = Set.new([
        'text', 'p'
    ])

    # @return   [Array<Hash{Symbol => <Symbol,String>}>]
    #   DOM transitions leading to the current state.
    attr_accessor :transitions

    # @param    [Hash]  options
    # @option   options [Page]  :page
    # @option   options [Array<Hash>]  :transitions
    def initialize( options )
        @page        = options[:page]
        @transitions = options[:transitions] || []
    end

    # @param    [Hash{Symbol => <Symbol,String>}]    transition
    #   Push the given transition to the DOM with element at key and the event
    #   as value.
    def push_transition( transition )
        @transitions << transition
    end

    # @return   [Integer]
    #   Depth of the current DOM -- amount of events that had to be triggered
    #   to reach the current state.
    def depth
        @transitions.select { |t| t.values.first != :request }.size
    end

    def hash
        @hash ||= rehash
    end

    def ==( other )
        hash == other.hash
    end

    # @private
    def clear_caches
        @hash = nil
    end

    private

    def rehash
        hash = ''
        @page.document.traverse do |node|
            next if IGNORE_FROM_HASH.include? node.name
            hash << node.name
            hash << attributes_to_str( node )
        end

        hash.persistent_hash
    end

    def attributes_to_str( node )
        node.attributes.inject({}){ |h, (name, attr)| h[name] = attr.value; h }.
            sort.to_s
    rescue NoMethodError
        ''
    end

end

end
end
