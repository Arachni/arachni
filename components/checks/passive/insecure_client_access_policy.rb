=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Checks::InsecureClientAccessPolicy < Arachni::Check::Base

    INSECURE_WILDCARDS = [
        '*',
        'http://*',
        'https://*'
    ]

    def run
        url = "#{page.parsed_url.up_to_path}clientaccesspolicy.xml"
        return if audited?( url )
        audited( url )

        http.get( url, performer: self, &method(:check_and_log) )
    end

    def check_and_log( response )
        return if response.code != 200

        policy = Nokogiri::XML( response.body )
        return if !policy

        INSECURE_WILDCARDS.each do |wildcard|
            permissive_access = policy.search( "domain[uri='#{wildcard}']" )
            next if permissive_access.empty?

            log(
                proof:    permissive_access.to_xml,
                vector:   Element::Server.new( response.url ),
                response: response
            )
            return
        end

    end

    def self.info
        {
            name:        'Insecure client-access policy',
            description: %q{
Checks `clientaccesspolicy.xml` files for wildcard domain policies.
},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            elements:    [ Element::Server ],

            issue:       {
                name:            %q{Insecure client-access policy},
                description:     %q{
The browser security model normally prevents web content from one domain from
accessing data from another domain. This is commonly known as the "same origin policy".

URL policy files grant cross-domain permissions for reading data. They permit
operations that are not permitted by default. The URL policy file for Silverlight
is located, by default, in the root directory of the target server, with the name
`ClientAccessPolicy.xml` (for example, at `www.example.com/ClientAccessPolicy.xml`).

When a domain is specified in `ClientAccessPolicy.xml`, the site declares that it
is willing to allow the operators of any servers in that domain to obtain any
document on the server where the policy file resides.

The `ClientAccessPolicy.xml` file deployed on this website opens the server to all
domains (use of a single asterisk "*" as a pure wildcard is supported).
},
                references:      {
                    'MSDN'  => 'https://msdn.microsoft.com/en-us/library/cc197955%28v=vs.95%29.aspx',
                    'OWASP' => 'https://www.owasp.org/index.php/Test_Cross_Origin_Resource_Sharing_%28OTG-CLIENT-007%29'
                },
                cwe:             16,
                severity:        Severity::LOW,
                remedy_guidance: %q{
Carefully evaluate which sites will be allowed to make cross-domain calls.

Consider network topology and any authentication mechanisms that will be affected
by the configuration or implementation of the cross-domain policy.
}
            }
        }
    end

end
