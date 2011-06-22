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
    # Lame hack to make XMLRPC output appear stream-ish to Sinatra
    # in order to send it back to the browser.
    #
    class OutputStream

        #
        #
        # @param    [Arachni::RPC::XML::Client::Instance]   instance
        # @param    [Integer]   lines   number of lines to output between refreshes
        #
        def initialize( instance, lines, &block )

            @lines    = lines
            @instance = instance
            @buffer  = []

            @icon_whitelist = {}
            [ 'status', 'ok', 'error', 'info' ].each {
                |icon|
                @icon_whitelist[icon] = "<img src='/icons/#{icon}.png' />"
            }

        end

        #
        # @param    [Array<Hash>]   output
        #
        def <<( output )
            @buffer << output.reverse
            @buffer.flatten!
        end

        def data
            data = ''
            each {
                |line|
                data << line
            }

            data
        end

        #
        # Sinatra (or Rack, not sure) expects the output to respond to "each" so we oblige.
        #
        def each

            self << @instance.service.output

            @last_output ||= ''
            cnt = 0

            if @buffer.empty?
                yield @last_output
            else
                @last_output = ''
            end

            while( ( out = @buffer.pop ) && ( ( cnt += 1 ) < @lines ) )

                type = out.keys[0]
                msg  = out.values[0]

                next if out.values[0].empty?

                icon = @icon_whitelist[type] || ''
                str = icon + CGI.escapeHTML( " #{out.values[0]}" ) + "<br/>"
                @last_output << str
                yield str

            end

            self << @instance.service.output
        end

    end
end
end
end
