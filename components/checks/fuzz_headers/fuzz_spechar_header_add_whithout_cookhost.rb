=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Fuzz with add headers content special char (withtout header host & cookie)
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
# @version 0.0.1
#
#todo
require 'simhash'
class Arachni::Checks::Fuzz_Header_Spechar_Add_withouthostcook < Arachni::Check::Base

    HEADERS = [
        'Accept',
        'Accept-Charset',
        'Accept-Encoding',
        'Accept-Language',
        'Accept-Datetime',
        'Authorization',
        'Cache-Control',
        'Connection',
        'Content-Length',
        'Content-MD5',
        'Content-Type',
        'Date',
        'Expect',
        'Forwarded',
        'From',
        'If-Match',
        'If-Modified-Since',
        'If-None-Match',
        'If-Range',
        'If-Unmodified-Since',
        'Max-Forwards',
        'Origin',
        'Pragma',
        'Proxy-Authorization',
        'Range',
        'Referer',
        'User-Agent',
        'Upgrade',
        'Via',
        'X-Requested-With',
        'DNT',
        'X-Forwarded-For',
        'X-Forwarded-Host',
        'X-Forwarded-Proto',
        'Front-End-Https',
        'X-Http-Method-Override',
        'X-ATT-DeviceId',
        'X-Wap-Profile',
        'Proxy-Connection',
        'X-UIDH',
        'X-Csrf-Token',
        'X-Request-ID',
        'X-Correlation-ID'
    ]

    SPECHAR = "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f?\@\x0d\x0a\x7e\x7f\x60\x5e\x5b\x7b\x7c\x2f\x5c"

    def self.http_options
        @http_options ||= {
            headers: HEADERS.inject({}) { |h, header| h.merge( header => SPECHAR ) }
        }
    end

    def run
        return if page.code != 200
        pbody_ori = page.body.dup.force_encoding('iso-8859-1').encode('utf-8')
        code_ori = page.code  
        hashbit_body = 64
        d_ori_body = pbody_ori.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
        ori_opts = page.request.to_h
        nhead = self.class.http_options
        ori_opts[:headers] = ori_opts[:headers].merge(nhead[:headers])
        http.request(ori_opts[:url].to_s, ori_opts, &method(:check_and_log) )
    end
    
    def check_and_log( response )
        code_new = response.to_page.code
        path = uri_parse( response.url ).path
        pbody_new = response.to_page.body.force_encoding("iso-8859-1").encode("utf-8")
        d_new_body = pbody_new.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
        if d_new_body != d_ori_body
            log(
                vector:   Element::Server.new( response.url ),
                response: response,
                proof:    "ADD HEADER WITH SPECHAR RESULT: code: #{code_new} -- #{response.status_line} -- #{response.to_s}"
            )
        end
    end

    def self.info
        {
            name:        'Strange response on Fuzz with add headers content special char (withtout header host & cookie)',
            description: %q{
Injects arbitrary special char in new header and checks if return error code, time_out or different content.
},
            elements:    Element::Server,
            author:      'Lionel PRAT <lionel.prat@gmail.com> ',
            version:     '0.0.1',

            issue:       {
                name:            %q{Strange response with request content special char in header add without cookie and host},
                description:     %q{
The server response is different than original request.
},
                tags:            %w(response strange special char in header add without cookie and host),
                severity:        Severity::INFORMATIONAL,
            }
        }
    end

end
