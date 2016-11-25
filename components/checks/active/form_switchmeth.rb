=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end
# Verify can't send request with switch method
#  GET -> POST or POST -> GET
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
require "addressable/uri"
class Arachni::Checks::Form_SwitchMeth < Arachni::Check::Base

    def run
        print_status 'Verify switch method...'
        code_ori = page.code    
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
                end
            end
            if form.method == :get
                ori_opts[:method] = :post
                ori_opts[:body] = uri.query
                action_url = form.action
            elsif form.method == :post
                ori_opts[:method] = :get
                action_url = form.action + "?" + uri.query
            end
            if ori_known
                ori_opts[:headers] = page.request.to_h[:headers]
            end
            http.request(action_url, ori_opts) do |res|
                code_new = res.to_page.code #res.code #integer
                if (code_new == code_ori)
                    #page identik or around value origin
                    if audited?( "#{res.to_page.url}::#{res.to_page.method}::#{code_new}::switch" )
                        print_info "Skipping already audited switch method page with code '#{code_new}' at '#{res.to_page.url}'"
                        return
                    end
            
                    audited( "#{res.to_page.url}::#{res.to_page.method}::#{code_new}::switch" )
                    
                    log( 
                        vector: form,
                        proof: "Page accept switch method: #{code_new}" 
                    )
                end
            end
        end
    end


    def self.info
        {
            name:        'Switch method',
            description: %q{
It's test to convert form by switch method (post or get).
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:            %q{Switch Method},
                description:     %q{
If switch method passed then it's possible to create uncrontrolled context...
},
                tags:            %w(acces control bypass),
                cwe:             650,
                severity:        Severity::LOW,
                remedy_guidance: %q{
You must verify than only good method is allowed.
}
            }
        }
    end

end
