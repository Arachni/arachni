=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# URL check in form, xml, json, link, header (no referer & host) OR find name param == *url*
#
#
# @author   Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::Ssrf < Arachni::Check::Base
    #TODO ADD host without proto://
    def self.regexp
        #TODO verify proto://IP match?
        @regexp ||= /[A-Za-z]+(?:\+[A-Za-z+]+)?:\/\/(?:[a-zA-Z0-9._-]+(?::[^@]*)?@)?(?:(?:\b(?:[0-9A-Za-z][0-9A-Za-z-]{0,62})(?:\.(?:[0-9A-Za-z][0-9A-Za-z-]{0,62}))*(\.?|\b)|(?:((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?|(?<![0-9])(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))(?![0-9])))(?::\b(?:[1-9][0-9]*)\b)?)?(?:(?:\/[A-Za-z0-9$.+!*'(){},~:;=@#%_\-]*)+(?:\?[A-Za-z0-9$.+!*'|(){},~@#%&\/=:;_?\-\[\]]*)?)?/
    end

    def run
        page.forms.each do |form|
            form.inputs.each do |n, v|
                if (v =~ self.class.regexp) or (n =~ /url/i)
                    log(
                        proof: "URI FIND IN FORM: " + v.to_s,
                        vector: form
                    )
                end
            end
        end
        
        page.response.headers.each do |k, v|
            next if (k =~ /referer:|host:/i)
            if (v =~ self.class.regexp)
                log(
                    vector: Element::Header.new( url: page.url, inputs: { k => v } ),
                    proof:  "URL FIND IN HEADER"
                )
            end
        end
        
        page.links.each do |link|
            link.inputs.each do |n, v|
                if (v =~ self.class.regexp) or (n =~ /url/i)
                    log(
                        proof: "URI FIND IN Link: " + v.to_s,
                        vector: link
                    )
                end
            end
        end
        
        page.jsons.each do |json|
            if (json.inputs.to_s =~ self.class.regexp)
                log(
                    proof: "URI FIND IN JSON: " + v.to_s,
                    vector: json
                )
            end
        end
        
        page.xmls.each do |xml|
            if (xml.inputs.to_s =~ self.class.regexp)
                log(
                    proof: "URI FIND IN XML: " + v.to_s,
                    vector: xml
                )
            end
        end
    end

    def self.info
        {
            name:        'Possible SSRF',
            description: %q{Scans pages for check proto://url scheme for possible SSRF.},
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',
            elements:    [ Element::Link, Element::Header, Element::JSON, Element::XML, Element::Form ],

            issue:       {
                name:            %q{Possible SSRF},
                description:     %q{
By providing URLs to unexpected hosts or ports, attackers can make it appear that the server is sending the request, possibly bypassing access controls such as firewalls that prevent the attackers from accessing the URLs directly. The server can be used as a proxy to conduct port scanning of hosts in internal networks, use other URLs such as that can access documents on the system (using file://), or use other protocols such as gopher:// or tftp://, which may provide greater control over the contents of requests.
Change destination by local:
127.0.0.1, 169.254.169.254, 0x7f.1, 0177.0000000000001, 2130706433, 0.0.0.0, 0x7f000001, ::1
Or change proto by:
gopher://, dict://, php://, jar://, tftp://, telnet://, ... (ex: http://php.net/manual/en/wrappers.php)
},
                references: {
                    'WebAppSec' => 'http://projects.webappsec.org/w/page/13246936/Information%20Leakage'
                },
                cwe:             918,
                severity:        Severity::LOW,
                remedy_guidance: %q{
Use filter very strict if field is really necessary.
},
            }
        }
    end

end
