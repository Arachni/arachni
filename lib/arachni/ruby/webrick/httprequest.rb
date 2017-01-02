=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
