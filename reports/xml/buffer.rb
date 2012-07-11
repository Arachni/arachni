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
                if value.is_a?( Array ) #&& name.downcase == 'set-cookie'
                    __buffer( "<field name=\"#{name}\" value=\"#{CGI.escapeHTML( value.join( "\n" ) )}\" />" )
                else
                    __buffer( "<field name=\"#{name}\" value=\"#{CGI.escapeHTML( value.to_s )}\" />" )
                end
            }
            end_tag( type )
        end

        def add_tags( tags )

            start_tag( 'tags' )
            tags.each {
                |name|
                __buffer( "<tag name=\"#{name}\" />" )
            }
            end_tag( 'tags' )
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
