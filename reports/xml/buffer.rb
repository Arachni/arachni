=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'base64'

module Arachni
module Reports

    module Buffer

        require 'cgi'

        def append( str )
            __add( str, true )
        end

        def simple_tag( tag, text, no_escape = false )
            start_tag( tag )
            __add( text, no_escape )
            end_tag( tag )
        end

        def start_tag( tag )
            __buffer( "\n<#{tag}>" )
        end

        def end_tag( tag )
            __buffer( "</#{tag}>\n" )
        end

        def add_cookie( name, value )
            __buffer( "<cookie name=\"#{name}\" value=\"#{value}\" />" )
        end

        def add_credentials( username, password )
            __buffer( "<credentials username=\"#{username}\" password=\"#{password}\" />" )
        end

        def add_reference( name, url )
            __buffer( "<reference name=\"#{name}\" url=\"#{url}\" />" )
        end

        def add_param( name, value )
            __buffer( "<param name=\"#{name}\" value=\"#{value}\" />" )
        end

        def add_mod( name )
            __buffer( "<module name=\"#{name}\" />" )
        end

        def add_headers( type, headers )

            start_tag( type )
            headers.each_pair {
                |name, value|
                __buffer( "<field name=\"#{name}\" value=\"#{CGI.escapeHTML( value.strip )}\" />" )
            }
            end_tag( type )
        end


        def buffer
            return @__buffer
        end

        def __buffer( str = '' )
            @__buffer ||= ''
            @__buffer += str
        end

        def __add( text, no_escape = false )
            if !no_escape
                __buffer( CGI.escapeHTML( text ) )
            else
                __buffer( text )
            end
        end

    end
end
end
