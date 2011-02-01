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

            @style   = '<link rel="stylesheet" href="/style.css" type="text/css" /><pre>'
            @refresh = '<meta http-equiv="refresh" content="1"/">'
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
            @buffer << output
            @buffer.flatten!
        end

        #
        # Sinatra (or Rack, not sure) expects the output to respond to "each" so we oblige.
        #
        def each

            self << @instance.service.output
            yield @style

            @@last_output ||= ''
            cnt = 0

            if @buffer.empty?
                yield @@last_output
            else
                @@last_output = ''
            end

            while( ( out = @buffer.pop ) && ( ( cnt += 1 ) < @lines ) )

                type = out.keys[0]
                msg  = out.values[0]

                next if out.values[0].empty?

                icon = @icon_whitelist[type] || ''
                str = icon + CGI.escapeHTML( " #{out.values[0]}" ) + "</br>"
                @@last_output << str
                yield str

            end

            self << @instance.service.output
            yield @refresh

        end

    end
end
end
end
