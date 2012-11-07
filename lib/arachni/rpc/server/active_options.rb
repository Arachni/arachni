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
module RPC
class Server

#
# It, for the most part, forwards calls to {::Arachni::Options} and intercepts
# a few that need to be updated at other places throughout the framework.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class ActiveOptions

    def initialize( framework )
        @opts = framework.opts

        (@opts.public_methods( false ) - public_methods( false ) ).each do |m|
            self.class.class_eval do
                define_method m do |*args|
                    @opts.send( m, *args )
                end
            end
        end
    end

    # @see Arachni::Options#set
    def set( options )
        options.each do |k, v|
            begin
                send( "#{k.to_s}=", v )
            rescue => e
                #ap e
                #ap e.backtrace
            end
        end
        true
    end

    # @see Arachni::Options#cookies=
    def cookies=( cookies )
        HTTP.update_cookies( cookies )
        @opts.cookies = cookies
    end

    # @see Arachni::Options#cookie_string=
    def cookie_string=( cookie_string )
        HTTP.update_cookies( cookie_string )
        @opts.cookie_string = cookie_string
    end

    # @see Arachni::Options#cookie_jar=
    def cookie_jar=( cookie_jar )
        HTTP.update_cookies( cookie_jar )
        @cookie_jar = cookie_jar
    end

end

end
end
end
