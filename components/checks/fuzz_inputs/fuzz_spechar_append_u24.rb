=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Strange response with fuzz request content special char
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
# @version 0.0.1
#
require 'simhash'
class Arachni::Checks::Fuzz_SpecharAppendu24 < Arachni::Check::Base

    def self.payloads
        #ADD %c5%unicode (voir code python)
        @payloads ||= [ "\xc4\xa3" ]
    end
          
    def run
        #get simhash of origin page
        check_simhash=[]
        check_timeout=false
        check_code=[]
        pbody_ori = page.body.dup.force_encoding('iso-8859-1').encode('utf-8')
        code_ori = page.code  
        hashbit_body = 64
        d_ori_body = pbody_ori.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
        #TODO: verify simhash verify compare on total or just /4
        # try to inject the headers into all vectors
        # and pass a block that will check for a positive result
        audit(
            self.class.payloads,
            format: [Format::APPEND]
        ) do |response, element|
            code_new = response.to_page.code
            path = uri_parse( response.url ).path
            pbody_new = response.to_page.body.force_encoding("iso-8859-1").encode("utf-8")
            d_new_body = pbody_new.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
            next if auditedsc?( "#{path}::#{response.code}::#{d_new_body}" )
            if response.timed_out?
                next if check_timeout
                log(
                    vector:   element,
                    response: response,
                    proof:    "Response error timeout: (simhash #{d_new_body} -- code #{response.code})"
                )
                check_timeout=true
                auditedsc( "#{path}::#{response.code}::#{d_new_body}" )
            elsif response.code.to_s.chars.first(1).join.to_i != 2 and code_new != code_ori and response.code.to_i != 404
                next if check_code.include?(response.code)
                log(
                    vector:   element,
                    response: response,
                    proof:    "Response error: (simhash #{d_new_body} -- code #{response.code})"+response.to_s
                )
                check_code.push(response.code)
                auditedsc( "#{path}::#{response.code}::#{d_new_body}" )
            else 
                if response.body.to_s =~ /<title>400 Bad Request<\/title>/i
                    next if check_simhash.include?(d_new_body)
                    log(
                        vector:   element,
                        response: response,
                        proof:    "Response error: (simhash #{d_new_body} -- code #{response.code})"+response.to_s
                    )
                    check_simhash.push(d_new_body)
                    auditedsc( "#{path}::#{response.code}::#{d_new_body}" )
                elsif d_new_body != d_ori_body
                    next if check_simhash.include?(d_new_body)
                    log(
                        vector:   element,
                        response: response,
                        proof:    "Response error: (simhash #{d_new_body} -- code #{response.code})"+response.to_s
                    )                
                    check_simhash.push(d_new_body)
                    auditedsc( "#{path}::#{response.code}::#{d_new_body}" )
                end
            end
        end
    end

    def self.info
        {
            name:        'Strange response with fuzz request content special char u24 (append)',
            description: %q{
Injects arbitrary special char and checks if return error code, time_out or different content.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Lionel PRAT <lionel.prat@gmail.com> ',
            version:     '0.0.1',

            issue:       {
                name:            %q{Strange response with fuzz request content special char u24 append},
                description:     %q{
The server response is different than original request.
},
                references:  {
                },
                tags:            %w(response strange special char u24 append),
                severity:        Severity::INFORMATIONAL,
            }
        }
    end

end
