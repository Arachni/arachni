=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Verify acces control if you can acces to page when cookie is different
#
# Multi case: 
#   - page acces user authentified 
#   - page acces different profile authentified
#   - page not accessible if identified (ask password lost, login, ...)
#
# @author Lionel PRAT <lionel.prat9@gmail.com>

## TODO!! Change cookie element by form, ...
require 'simhash'

class Arachni::Checks::Access_Control < Arachni::Check::Base

    def run
        print_status 'Verify acces control...'
        print_status 'Simulating another user.'
        print_status 'By default use cookie.txt, if empty use connect without cookie'
        # parse cookie.txt
        tmp_cookies = []
        begin
            File.open((Dir.pwd) + '/cookie.txt') do |fh|
                fh.each_line do |linex|
                    linex.delete!("\n")
                    tmp_cookies.push(Element::Cookie.from_string(page.url,linex))
                end
            end
        rescue
            print_debug_level_2 "Error to open file cookie.txt not existe in current dir #{Dir.pwd}."
            tmp_cookies = []
        end
        if tmp_cookies.length == 0
           tmp_cookies = []
        end
        pbody_ori = page.body.dup.force_encoding('iso-8859-1').encode('utf-8') #string
        pbody_ori_len = pbody_ori.length
        code_ori = page.code     
        hashbit_title = 8
        hashbit_body = 8
        d_ori_body = pbody_ori.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
        # request page without cookies, simulating a logged-out user
        if tmp_cookies.empty?
            print_info "Check control with cookie empty (because file cookie.txt not exist)."
            tmp_cookie = Element::Cookie.from_string(page.url,"")
            ori_opts = page.request.to_h
            ori_opts[:headers] = page.request.to_h[:headers].delete!(:Cookie) 
            http.request( ori_opts, cookies: {}, no_cookie_jar: true ) do |res|
                print_info "Check control access #{page.url} => #{res.to_page.request.headers}"
                #code & timeout 
                code_new = res.to_page.code #res.code #integer
                ## simhash body content
                #page with cookie modified
                pbody_new = res.to_page.body.force_encoding('iso-8859-1').encode('utf-8') #string
                pbody_new_len = pbody_new.length
                #ptitle_new = res.to_page.title.force_encoding('iso-8859-1').encode('utf-8') #string
                #page origine
                #ptitle_ori = page.title.force_encoding('iso-8859-1').encode('utf-8') #string     
                #+/- 20 poucent simhash distance
                #d_new_title = ptitle_new.simhash(:hashbits => hashbit_title).to_s.chars.first(hashbit_title/4).join.to_i
                #d_ori_title = ptitle_ori.simhash(:hashbits => hashbit_title).to_s.chars.first(hashbit_title/4).join.to_i
                d_new_body = pbody_new.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
                #hashbit: 8->0-255 16->0-65535 32-> ...
                #choose hashbit by length of page
                #check (hashbit/4) first digit identique: ex 8/4 = 2first bit SIMHASH_VALUE.to_s.chars.first(hashbit/4).join.to_i
                if (code_new == code_ori) and (d_new_body == d_ori_body) #and (d_new_title == d_ori_title)
                    #page identik or around value origin
                    log_cookie( res, tmp_cookie, d_new_body)
                end
            end
        else
            for tmp_cookie in tmp_cookies
                #page.cookie_jar
                if !(page.cookie_jar === test_cookie)
                    ori_opts = page.request.to_h
                    ori_opts[:headers] = page.request.to_h[:headers].delete!(:Cookie) 
                    http.request( ori_opts, cookies: {}, cookie_jar: tmp_cookie ) do |res|
                        print_info "Check control access #{page.url} => #{res.to_page.request.headers}"
                        #code & timeout 
                        code_new = res.to_page.code #res.code #integer
                        ## simhash body content
                        #page with cookie modified
                        pbody_new = res.to_page.body.force_encoding('iso-8859-1').encode('utf-8') #string
                        pbody_new_len = pbody_new.length
                        #ptitle_new = res.to_page.title.force_encoding('iso-8859-1').encode('utf-8') #string
                        #page origine
                        #ptitle_ori = page.title.force_encoding('iso-8859-1').encode('utf-8') #string
                        #+/- 20 poucent simhash distance
                        #d_new_title = ptitle_new.simhash(:hashbits => hashbit_title).to_s.chars.first(hashbit_title/4).join.to_i
                        #d_ori_title = ptitle_ori.simhash(:hashbits => hashbit_title).to_s.chars.first(hashbit_title/4).join.to_i
                        d_new_body = pbody_new.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
                        #hashbit: 8->0-255 16->0-65535 32-> ...
                        #choose hashbit by length of page
                        #check (hashbit/4) first digit identique: ex 8/4 = 2first bit SIMHASH_VALUE.to_s.chars.first(hashbit/4).join.to_i
                        if (code_new == code_ori) and (d_new_body == d_ori_body) #and (d_new_title == d_ori_title)
                            #page identik or around value origin
                            log_cookie( res,  tmp_cookie, d_new_body)
                        end
                    end
                end
            end
        end
    end

    def log_cookie(res, cookie, d_new_body)
        if audited?( "#{page.url}::#{cookie}::#{d_new_body}" )
            print_info "Skipping already audited access control page with cookie '#{tmp_cookie}' at '#{page.url}'"
            return
        end

        audited( "#{page.url}::#{cookie}::#{d_new_body}" )

        log( 
            vector: Element::Cookie.new(url: page.url), 
            proof: "Page same hashbit with different cookie: #{d_new_body} -- #{res.to_page.body}" 
        )
        
        print_ok "Found access control bypass at '#{page.url}'"
    end

    def self.info
        {
            name:        'Acces control',
            description: %q{
It uses differential analysis SIMHASH to determine if access to page with another cookie (or not cookie) give same result.
},
            elements:    [ Element::Cookie ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:            %q{Acces control},
                description:     %q{
If a problem in verification, it's possible to bypass access control.
},
                references:  {
                    'SITE' => 'http://www.'
                },
                tags:            %w(acces control bypass),
                cwe:             352,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
You must verify rigth access ressource in code.
}
            }
        }
    end

end
