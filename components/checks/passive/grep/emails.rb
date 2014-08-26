=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for and logs e-mail addresses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2.1
class Arachni::Checks::Emails < Arachni::Check::Base

    def run
        match_and_log( /[A-Z0-9._%+-]+(?:@|\s*\[at\]\s*)[A-Z0-9.-]+(?:\.|\s*\[dot\]\s*)[A-Z]{2,4}/i ) do |email|
            return false if audited?( email )
            audited( email )
        end
    end

    def self.info
        {
            name:        'E-mail address',
            description: %q{Greps pages for disclosed e-mail addresses.},
            elements:    [ Element::Body ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.1',

            issue:       {
                name:            %q{E-mail address disclosure},
                description:     %q{
Email addresses are typically found on "Contact us" pages, however, they can also
be found within scripts or code comments of the application. They are used to
provide a legitimate means of contacting an organisation.

As one of the initial steps in information gathering, cyber-criminals will spider
a website and using automated methods collect as many email addresses as possible,
that they may then use in a social engineering attack.

Using the same automated methods, Arachni was able to detect one or more email
addresses that were stored within the affected page.
},
                cwe:             200,
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{E-mail addresses should be presented in such
                    a way that it is hard to process them automatically.}
            },
            max_issues: 25
        }
    end

end
