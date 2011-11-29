=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# Override the on_complete methods of Typhoeus adding support
# for multiple on_complete blocks.
#
# Also added support for on demand training of the response and
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
            if( multi || @multiple_callbacks )
                @multiple_callbacks = true
                @on_complete << block
            else
                @on_complete = block
            end

        end

        def on_complete=( multi = false, proc )

            # remember user preference for subsequent calls
            if( multi || @multiple_callbacks )
                @multiple_callbacks = true
                @on_complete << proc
            else
                @on_complete = proc
            end

        end

        def call_handlers

            if @on_complete.is_a? Array

                @on_complete.each do |callback|
                    @handled_response << callback.call(response)
                end

            else
                @handled_response << @on_complete.call(response)
            end

          call_after_complete
        end

        def train?
            @train
        end

        def train!
            @train = true
        end

        def update_cookies?
            @update_cookies
        end

        def update_cookies!
            @update_cookies = true
        end

    end

end
