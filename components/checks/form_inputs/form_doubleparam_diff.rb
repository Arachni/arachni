=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end
# Verify can't send request with other method
#
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
require "addressable/uri"
require 'simhash'

class Arachni::Checks::Form_DoubleParamDiff < Arachni::Check::Base

    def run
        print_status 'Verify double input param with different value in form...'
        code_ori = page.code
        pbody_ori = page.body.dup.force_encoding('iso-8859-1').encode('utf-8') #string
        pbody_ori_len = pbody_ori.length  
        hashbit_title = 8
        hashbit_body = 8
        d_ori_body = pbody_ori.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
        # request switch method
        #print_info "forms : #{page.forms}"
        page.forms.each do |form|
            ori_opts = {}
            action_url = ""
            ori_known = true
            #TODO verify page.code is identik to form information, if not ok, create request original for get info
            #print_info "form code: #{page.code}"
            uri = Addressable::URI.new
            uri.query_values = form.inputs
            uri_act = Addressable::URI.parse(page.url.to_s)
            if uri_act.port
                url_ver = uri_act.scheme.to_s + "://" + uri_act.host.to_s + ":" + uri_act.port.to_s + uri_act.path.to_s
            else
                url_ver = uri_act.scheme.to_s + "://" + uri_act.host.to_s + uri_act.path.to_s
            end
            #print_info "IF #{url_ver} != #{form.action}"
            if url_ver != form.action
                #create request origin
                orig_opts = {}
                ori_known = false
                if form.method == :post
                    orig_opts[:method] = :post
                    orig_opts[:body] = uri.query
                    actiong_url = form.action
                elsif form.method == :get
                    orig_opts[:method] = :get
                    actiong_url = form.action + "?" + uri.query
                end
                http.request(actiong_url, orig_opts) do |resg|
                    code_ori = resg.to_page.code #res.code #integer
                    pbody_ori = resg.to_page.body.dup.force_encoding('iso-8859-1').encode('utf-8') #string
                    pbody_ori_len = pbody_ori.length  
                    hashbit_title = 8
                    hashbit_body = 8
                    d_ori_body = pbody_ori.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
                end
            end
            inputs_list = {}
            form.inputs.keys.each do |key|
                inputs_list[key] = [ form.inputs[key], "", "\x00\x00\x00\x00"]
            end
            uri.query_values = inputs_list
            if form.method == :post
                ori_opts[:method] = :post
                ori_opts[:body] = uri.query
                action_url = form.action
            elsif form.method == :get
                ori_opts[:method] = :get
                action_url = form.action + "?" + uri.query
            end
            if ori_known
                ori_opts[:headers] = page.request.to_h[:headers]
            end
            http.request(action_url, ori_opts) do |res|
                code_new = res.to_page.code #res.code #integer
                pbody_new = res.to_page.body.dup.force_encoding('iso-8859-1').encode('utf-8') #string
                pbody_new_len = pbody_new.length  
                d_new_body = pbody_new.simhash(:hashbits => hashbit_body).to_s.chars.first(hashbit_body/4).join.to_i
                if (code_new != code_ori) or (d_new_body != d_ori_body)
                    #page identik or around value origin
                    if audited?( "#{res.to_page.url}::#{res.to_page.method}::#{code_new}::form_doubleparamdiff" )
                        print_info "Skipping already audited switch method page with code '#{code_new}' at '#{res.to_page.url}'"
                        return
                    end
            
                    audited( "#{res.to_page.url}::#{res.to_page.method}::#{code_new}::form_doubleparamdiff" )
                    
                    log( 
                        vector: form,
                        proof: "Page with double param with different value change result: #{code_new}" 
                    )
                end
            end
        end
    end


    def self.info
        {
            name:        'Form with double param different',
            description: %q{
It's test to send form with double inputs (2x) param with different value.
},
            elements:    [ Element::Form ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:            %q{Form with double param different},
                description:     %q{
If test passed then it's possible to create uncontrolled context, ...
},
                tags:            %w(acces control bypass),
                cwe:             650,
                severity:        Severity::LOW,
                remedy_guidance: %q{
You must verify taint data and reject bad case.
}
            }
        }
    end

end
