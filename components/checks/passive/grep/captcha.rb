=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2
class Arachni::Checks::CAPTCHA < Arachni::Check::Base

    CAPTCHA_RX = /captcha/i

    def run
        return if !page.body =~ CAPTCHA_RX

        # since we only care about forms parse the HTML and match forms only
        page.document.css( 'form' ).each do |form|
            # pretty dumb way to do this but it's a pretty dumb issue anyways...
            next if !((form_html = form.to_s) =~ CAPTCHA_RX)

            log(
                signature: CAPTCHA_RX,
                proof:     form_html,
                vector:    Element::Form.from_document( page.url, form ).first
            )
        end
    end

    def self.info
        {
            name:        'CAPTCHA',
            description: %q{Greps pages for forms with CAPTCHAs.},
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',

            issue:       {
                name:        %q{CAPTCHA protected form},
                description: %q{Arachni can't audit CAPTCHA protected forms, consider auditing manually.},
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end

end
