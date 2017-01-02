=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# XSS in URL path check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XssPath < Arachni::Check::Base

    def self.tag
        @tag ||= 'my_tag_' + random_seed
    end

    def self.string
        @string ||= '<' + tag + '/>'
    end

    def self.requests
        @requests ||= [
            [ string, {} ],
            [ '>"\'>' + string, {} ],

            [ '', { string => '' } ],
            [ '', { '>"\'>' + string => '' } ],

            [ '', { '' => string } ],
            [ '', { '' => '>"\'>' + string } ]
        ]
    end

    def run
        path = get_path( page.url )

        return if audited?( path )
        audited( path )

        self.class.requests.each do |str, parameters|
            url  = path + str
            print_status "Checking for: #{url}"

            http.get( url, parameters: parameters, &method(:check_and_log) )
        end
    end

    def check_and_log( response )
        return if !response.html?

        body = response.body.downcase

        # check for the existence of the tag name in the response before
        # parsing to verify, no reason to waste resources...
        return if !body.include?( self.class.string )

        return if Arachni::Parser.parse(
            response.body,
            whitelist:     [self.class.tag],
            stop_on_first: [self.class.tag]
        ).nodes_by_name( self.class.tag ).empty?

        log vector: Element::Path.new( response.url ),
            proof: self.class.string, response: response
    end


    def self.info
        {
            name:        'XSS in path',
            description: %q{Cross-Site Scripting check for path injection},
            elements:    [ Element::Path ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1.11',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in path},
                description:     %q{
Client-side scripts are used extensively by modern web applications.
They perform from simple functions (such as the formatting of text) up to full
manipulation of client-side data and Operating System interaction.

Cross Site Scripting (XSS) allows clients to inject scripts into a request and
have the server return the script to the client in the response. This occurs
because the application is taking untrusted data (in this example, from the client)
and reusing it without performing any validation or sanitisation.

If the injected script is returned immediately this is known as reflected XSS.
If the injected script is stored by the server and returned to any client visiting
the affected page, then this is known as persistent XSS (also stored XSS).

Arachni has discovered that it is possible to insert script content directly into
the requested PATH and have it returned in the server's response.
For example `HTTP://yoursite.com/INJECTION_HERE/`, where `INJECTION_HERE`
represents the location where the Arachni payload was injected.
},
                references:  {
                    'Secunia' => 'http://secunia.com/advisories/9716/',
                    'WASC'    => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP'   => 'https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
                },
                tags:            %w(xss path injection regexp),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
To remedy XSS vulnerabilities, it is important to never use untrusted or unfiltered
data within the code of a HTML page.

Untrusted data can originate not only form the client but potentially a third
party or previously uploaded file etc.

Filtering of untrusted data typically involves converting special characters to
their HTML entity encoded counterparts (however, other methods do exist, see references).
These special characters include:

* `&`
* `<`
* `>`
* `"`
* `'`
* `/`

An example of HTML entity encoding is converting `<` to `&lt;`.

Although it is possible to filter untrusted input, there are five locations
within an HTML page where untrusted input (even if it has been filtered) should
never be placed:

1. Directly in a script.
2. Inside an HTML comment.
3. In an attribute name.
4. In a tag name.
5. Directly in CSS.

Each of these locations have their own form of escaping and filtering.

_Because many browsers attempt to implement XSS protection, any manual verification
of this finding should be conducted using multiple different browsers and browser
versions._
}
            }
        }
    end

end
