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

module Arachni
module UI
module Web

    #
    # This used to be a stream in the past, now it's just a compat class.
    #
    class OutputStream

        def initialize( output, lines, &block )
            @lines  = lines
            @output = output
            @buffer = []

            @icon_whitelist = {}
            [ 'status', 'ok', 'error', 'info', 'bad' ].each {
                |icon|
                @icon_whitelist[icon] = "<img src='/icons/#{icon}.png' />"
            }

        end

        def format
            str = ''
            cnt = 0

            while( ( out = @output.pop ) && ( ( cnt += 1 ) < @lines ) )

                type = out.keys[0]
                msg  = out.values[0]

                next if out.values[0].empty?

                icon = @icon_whitelist[type.to_s] || ''
                str += icon + CGI.escapeHTML( " #{out.values[0]}" ) + "<br/>"
            end

            return str
        end

    end
end
end
end
