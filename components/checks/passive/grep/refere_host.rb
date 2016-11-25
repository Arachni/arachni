=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Search HOST site web in body (possible HOST ATTACK /cache poisoning)
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::Referehost < Arachni::Check::Base

    def run
        print_info "HOST == #{page.parsed_url.host.to_s}"
        regexp ||= /#{page.parsed_url.host.to_s}/im
        match_and_log( regexp ) { |m| m && !m.empty? }
    end

    def self.info
        description = %q{If host is present in page then it's possible to change HOST by injection header.}
        {
            name:        'Refere to host',
            description: description,
            elements:    [ Element::Body ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:        %q{Refere to host},
                cwe:         200,
                description: description,
                severity:    Severity::INFORMATIONAL
            }
        }
    end

end
