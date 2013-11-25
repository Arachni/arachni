=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Looks for and logs e-mail addresses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Checks::EMails < Arachni::Check::Base

    def run
        match_and_log( /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i ) do |email|
            return false if audited?( email )
            audited( email )
        end
    end

    def self.info
        {
            name:        'E-mail address',
            description: %q{Greps pages for disclosed e-mail addresses.},
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:            %q{E-mail address disclosure},
                description:     %q{An e-mail address is being disclosed.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{E-mail addresses should be presented in such
                    a way that it is hard to process them automatically.}
            },
            max_issues: 25
        }
    end

end
