=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end
require 'json'
require 'nokogiri'
require "addressable/uri"
# Verify can't send request with XML FOrmat
#
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
    
class Arachni::Checks::Form_XmlFmt < Arachni::Check::Base
    #source: http://stackoverflow.com/questions/11933451/converting-nested-hash-into-xml-using-nokogiri
    def generate_xml(data, parent = false, opt = {})
        return if data.to_s.empty?
        return unless data.is_a?(Hash)
    
        unless parent
            # assume that if the hash has a single key that it should be the root
            root, data = (data.length == 1) ? data.shift : ["root", data]
            builder = Nokogiri::XML::Builder.new(opt) do |xml|
                xml.send(root) {
                    generate_xml(data, xml)
                }
            end
    
            return builder.to_xml
        end
    
        data.each { |label, value|
            if value.is_a?(Hash)
                attrs = value.fetch('@attributes', {})
                # also passing 'text' as a key makes nokogiri do the same thing
                text = value.fetch('@text', '') 
                parent.send(label, attrs, text) { 
                    value.delete('@attributes')
                    value.delete('@text')
                    generate_xml(value, parent)
                }
    
            elsif value.is_a?(Array)
                value.each { |el|
                    # lets trick the above into firing so we do not need to rewrite the checks
                    el = {label => el}
                    generate_xml(el, parent) 
                }
    
            else
                parent.send(label, value)
            end
        }
    end

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
            ori_opts[:method] = :post
            action_url = form.action
            ori_opts[:body] = generate_xml(form.inputs)

            print_info "XML: #{ori_opts[:body]}"
            if ori_known
                ori_opts[:headers] = page.request.to_h[:headers].merge({ 'Content-Type' => 'application/xml', 'Accept' => 'application/xml' })
            else
                ori_opts[:headers] = { 'Content-Type' => 'application/xml', 'Accept' => 'application/xml' }
            end
            #print_info "SEND JSON ORI #{ori_opts}"
            http.request(action_url, ori_opts) do |res|
                code_new = res.to_page.code #res.code #integer
                if (code_new == code_ori)
                    #page identik or around value origin
                    if audited?( "#{res.to_page.url}::#{res.to_page.method}::#{code_new}::xmlfmt" )
                        print_info "Skipping already audited xml format method page with code '#{code_new}' at '#{res.to_page.url}'"
                        return
                    end
            
                    audited( "#{res.to_page.url}::#{res.to_page.method}::#{code_new}::xmlfmt" )
                    
                    log( 
                        vector: form,
                        proof: "Page accept Json Format: #{code_new}" 
                    )
                end
            end
        end
    end



    def self.info
        {
            name:        'Form Send format XML',
            description: %q{
Verify if application accept send form with xml format.
},
            elements:    [ Element::Form ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:            %q{Form Send format XML},
                description:     %q{
If application  accept xml format then it's possible to create uncontrolled context and maybe XXE 
},
                references:  {
                    'SITE' => 'http://www.'
                },
                tags:            %w(acces control bypass),
                cwe:             352,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
You must verify than only good method and format is allowed.
}
            }
        }
    end

end
