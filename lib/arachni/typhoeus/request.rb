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

#
# Overrides the on_complete methods of Typhoeus adding support
# for multiple on_complete blocks.
#
# Also adds support for on demand training of the response and
# incremental request id numbers.
#
module Typhoeus
class Request

    attr_accessor :id

    alias :old_initialize :initialize
    def initialize( url, options = {} )
        old_initialize( url, options )

        @on_complete        = []
        @handled_response   = []
        @multiple_callbacks = false
        @train              = false
        @update_cookies     = false
    end

    def on_complete( multi = false, &block )
        # remember user preference for subsequent calls
        if multi || @multiple_callbacks
            @multiple_callbacks = true
            @on_complete << block
        else
            @on_complete = block
        end

    end

    def call_handlers
        if @on_complete.is_a? Array
            @on_complete.each do |callback|
                @handled_response << callback.call( response )
            end
        else
            @handled_response << @on_complete.call( response )
        end

      call_after_complete
    end

    def train?
        @train
    end

    def train
        @train = true
    end

    def update_cookies?
        @update_cookies
    end

    def update_cookies
        @update_cookies = true
    end

end
end
