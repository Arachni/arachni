=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# XSS in URL path check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.8
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XSSPath < Arachni::Check::Base

    def self.tag
        @tag ||= 'my_tag_' + seed
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

            http.get( url, parameters: parameters ) do |response|
                check_and_log( response )
            end
        end
    end

    def check_and_log( response )
        # check for the existence of the tag name in the response before
        # parsing to verify, no reason to waste resources...
        return if !response.body || !response.body.include?( self.class.string )

        # see if we managed to successfully inject our element
        return if Nokogiri::HTML( response.body ).css( self.class.tag ).empty?

        log vector: Element::Path.new( response.url ),
            proof: self.class.string, response: response
    end


    def self.info
        {
            name:        'XSS in path',
            description: %q{Cross-Site Scripting check for path injection},
            elements:    [ Element::Path ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.8',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in path},
                description:     %q{Client-side code, like JavaScript, can
    be injected into the web application.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss path injection regexp),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: %q{Path must be validated and filtered
                    before being returned as part of the HTML code of a page.}
            }

        }
    end

end
