=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

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
            [ 'status', 'ok', 'error', 'info' ].each {
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
