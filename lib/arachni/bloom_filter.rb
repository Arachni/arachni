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
# Lightweight Bloom-filter implementation.
#
# It uses the return value of the #hash method of the given objects instead of
# the objects themselves.
#
# This leads to decreased memory consumption and faster comparisons during look-ups.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::BloomFilter

    def initialize
        @hash = Hash.new( false )
    end

    #
    # @param    [#hash] obj object to insert
    #
    # @return   [Arachni::BloomFilter]  self
    #
    def <<( obj )
        @hash[obj.hash] = true
        self
    end
    alias :add :<<

    #
    # @param    [#hash] obj object to delete
    #
    # @return   [Arachni::BloomFilter]  self
    #
    def delete( obj )
        @hash.delete( obj.hash )
        self
    end

    #
    # @param    [#hash] obj object to check
    #
    # @return   [Bool]
    #
    def include?( obj )
        @hash[obj.hash]
    end

    def empty?
        @hash.empty?
    end

    def size
        @hash.size
    end

    def clear
        @hash.clear
    end
end
