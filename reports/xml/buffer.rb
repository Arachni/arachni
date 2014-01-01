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

require 'cgi'

module Arachni::Reports::XML::Buffer

    def simple_tag( tag, text, no_escape = false )
        start_tag tag
        append( no_escape ? text : escape( text ) )
        end_tag tag
    end

    def start_tag( tag )
        append "\n<#{tag}>"
    end

    def end_tag( tag )
        append "</#{tag}>\n"
    end

    def add_cookie( name, value )
        append "<cookie name=\"#{name}\" value=\"#{value}\" />"
    end

    def add_credentials( username, password )
        append "<credentials username=\"#{username}\" password=\"#{password}\" />"
    end

    def add_reference( name, url )
        append "<reference name=\"#{name}\" url=\"#{url}\" />"
    end

    def add_remark( commenter, remark )
        append "<remark by=\"#{commenter}\" text=\"#{escape( remark )}\" />"
    end

    def add_param( name, value )
        append "<param name=\"#{name}\" value=\"#{escape(value)}\" />"
    end

    def add_mod( name )
        append "<module name=\"#{name}\" />"
    end

    def add_headers( type, headers )
        start_tag type
        headers.each_pair do |name, value|
            add_header( name, value )
        end
        end_tag type
    end

    def add_header( name, value )
        if value.is_a?( Array ) #&& name.downcase == 'set-cookie'
            append "<field name=\"#{name}\" value=\"#{escape( value.join( "\n" ) )}\" />"
        else
            append "<field name=\"#{name}\" value=\"#{escape( value )}\" />"
        end
    end

    def add_tags( tags )
        start_tag 'tags'
        tags.each { |name| append "<tag name=\"#{name}\" />" }
        end_tag 'tags'
    end

    def buffer
        @xml
    end

    def escape( str )
        CGI.escapeHTML( str.to_s )
    end

    def append( str = '' )
        str = str.to_s

        @xml ||= ''
        #@xml += (no_escape ? str : escape( str ))
        @xml << str
    end

end
