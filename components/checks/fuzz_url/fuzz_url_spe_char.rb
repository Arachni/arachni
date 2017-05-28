=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# FUzz url with special char
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
require 'simhash'

class Arachni::Checks::fuzz_url_spe_char < Arachni::Check::Base

    def run
        print_status 'Test FUZZ URL with special char'
        return if page.code != 200
        path = get_path( page.url )
        hashbit_body = 64
        parsed_path = uri_parse( path ).path
        return if audited?( parsed_path )
        print_info "PATH: #{path} -- PARSED PATH: #{parsed_path}"
        audited( parsed_path )
        return if true
        playloads = ["\x20", "\x21", "\x22", "\x23", "\x24", "\x25", "\x26", "\x27", "\x28", "\x29", "\x2a", "\x2b", "\x2c", "\x2d", "\x2e", "\x2f","\x10", "\x11", "\x12", "\x13", "\x14", "\x15", "\x16", "\x17", "\x18", "\x19", "\x1a", "\x1b", "\x1c", "\x1d", "\x1e", "\x1f", "\x00", "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0a", "\x0b", "\x0c", "\x0d", "\x0e", "\x0f", '?', '@', "\x5c", "\x0d\x0a", "\xff", "\x7e", "\x7f", "\x60", "\x5e", "\x5b", "\x7b", "\x7c", "\x2f"]
        playloads.each do |playload|
            url = path + playload
            http.get( url ) do |res|
                next if !res
                code_new = res.to_page.code
                pbody_new = response.to_page.body.force_encoding("iso-8859-1").encode("utf-8")
                d_new_body = pbody_new.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
                next if auditedsc?( "URL_SPE_CHAR::#{code_new}::#{d_new_body}" )
                auditedsc( "URL_SPE_CHAR::#{code_new}::#{d_new_body}" )
                log(
                    vector:   Element::Path.new( res.url ),
                    response: res,
                    proof:    "Response error timeout: (simhash #{d_new_body} -- code #{res.code})"
                )
            end
        end
    end

    def self.info
        {
            name:        'Fuzz Url special char test',
            description: %q{
Send special char in path url and verify response (fuzz)
},
            elements:    [ Element::Path ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:            %q{Fuzz Url special char},
                description:     %q{
If url parse bad implemented.
},
                tags:            %w(Fuzz url spe char),
                severity:        Severity::INFORMATIONAL,
            }
        }
    end

end
