=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# CVS/SVN users recon check.
#
# Scans every page for CVS/SVN users.
#
# @author   Tasos Laskos <tasos.laskos@gmail.com>
# @version  0.3
class Arachni::Checks::CvsSvnUsers < Arachni::Check::Base

    def self.regexps
        @regexps ||= [
            /\$Author: (\w+) \$/,
            /\$Locker: (\w+) \$/,
            /\$Header: .* (\w+) Exp \$/,
            /\$Id: .* (\w+) Exp \$/,
            /\$Header: .* (\w+) (?<!Exp )\$/,
            /\$Id: .* (\w+) (?<!Exp )\$/
        ]
    end

    def run
        match_and_log( self.class.regexps )
    end

    def self.info
        {
            name:        'CVS/SVN users',
            description: %q{Scans every page for CVS/SVN users.},
            elements:    [ Element::Body ],
            author:      'Tasos Laskos <tasos.laskos@gmail.com>',
            version:     '0.3',

            issue:       {
                name:            %q{CVS/SVN user disclosure},
                description:     %q{A CVS or SVN user is disclosed in the body of the HTML page.},
                references: {
                    'CWE' => 'http://cwe.mitre.org/data/definitions/200.html'
                },

                cwe:             200,
                severity:        Severity::LOW,
                remedy_guidance: %q{Remove all CVS and SVN users from the body of the HTML page.},
            },
            max_issues: 25
        }
    end

end
