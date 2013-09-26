=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

class WEBrick::HTTPRequest

    def parse_uri(str, scheme="http")
        if @config[:Escape8bitURI]
            str = HTTPUtils::escape8bit(str)
        end
        str.sub!(%r{\A/+}o, '/')
        uri = Arachni::URI( str )
        return uri if uri.absolute?
        if @forwarded_host
            host, port = @forwarded_host, @forwarded_port
        elsif self["host"]
            pattern = /\A(#{URI::REGEXP::PATTERN::HOST})(?::(\d+))?\z/n
            host, port = *self['host'].scan(pattern)[0]
        elsif @addr.size > 0
            host, port = @addr[2], @addr[1]
        else
            host, port = @config[:ServerName], @config[:Port]
        end
        uri.scheme = @forwarded_proto || scheme
        uri.host = host
        uri.port = port ? port.to_i : nil
        return URI::parse(uri.to_s)
    end

end
