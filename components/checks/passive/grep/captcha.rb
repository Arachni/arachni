=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::Captcha < Arachni::Check::Base

    CAPTCHA_RX = /.*captcha.*/i

    def run
        return if !page.body =~ CAPTCHA_RX

        # since we only care about forms parse the HTML and match forms only
        page.document.nodes_by_name( 'form' ).each do |form|
            # pretty dumb way to do this but it's a pretty dumb issue anyways...
            next if !(proof = find_proof( form ))

            log(
                signature: CAPTCHA_RX,
                proof:     proof,
                vector:    Element::Form.from_node( page.url, form ).first
            )
        end
    end

    def find_proof( node )
        node.nodes_by_name('input').each do |input|
                html = input.to_html
                return html if html =~ CAPTCHA_RX
            end

        nil
    end

    def self.info
        {
            name:        'CAPTCHA',
            description: %q{Greps pages for forms with CAPTCHAs.},
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.2',

            issue:       {
                name:        %q{CAPTCHA protected form},
                description: %q{
To prevent the automated abuse of a page, applications can implement what is
known as a CAPTCHA.

These are used to ensure human interaction with the application and are often
used on forms where the application conducts sensitive actions. These typically
include user registration, or submitting emails via "Contact Us" pages etc.

Arachni has flagged this not as a vulnerability, but as a prompt for the
penetration tester to conduct further manual testing on the CAPTCHA function, as
Arachni cannot audit CAPTCHA protected forms.

Testing for insecurely implemented CAPTCHA is a manual process, and an insecurely
implemented CAPTCHA could allow a cyber-criminal a means to abuse these sensitive
actions.
},
                severity:    Severity::INFORMATIONAL,
                remedy_guidance: %q{
Although no remediation may be required based on this finding alone, manual
testing should ensure that:

1. The server keeps track of CAPTCHA tokens in use and has the token terminated
    after its first use or after a period of time. Therefore preventing replay attacks.
2. The CAPTCHA answer is not hidden in plain text within the response that is
    sent to the client.
3. The CAPTCHA image should not be weak and easily solved.
},
            },
            max_issues: 25
        }
    end

end
