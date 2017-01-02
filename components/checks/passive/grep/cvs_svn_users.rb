=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# CVS/SVN users recon check.
#
# Scans every page for CVS/SVN users.
#
# @author   Tasos Laskos <tasos.laskos@arachni-scanner.com>
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
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3.1',

            issue:       {
                name:            %q{CVS/SVN user disclosure},
                description:     %q{
Concurrent Version System (CVS) and Subversion (SVN) provide a method for
application developers to control different versions of their code.

Occasionally, the developer's version or user information can be stored incorrectly
within the code and may be visible to the end user (either in the HTML or code
comments). As one of the initial steps in information gathering, cyber-criminals
will spider a website and using automated methods attempt to discover any CVS/SVN
information that may be present in the page.

This will aid them in developing a better understanding of the deployed
application (potentially through the disclosure of version information), or it
may assist in further information gathering or social engineering attacks.

Using the same automated methods, Arachni was able to detect CVS or SVN details
stored within the affected page.
},
                references: {
                    'CWE' => 'http://cwe.mitre.org/data/definitions/200.html'
                },
                cwe:             200,
                severity:        Severity::LOW,
                remedy_guidance: %q{
CVS and/or SVN information should not be displayed to the end user.

This can be achieved by removing this information all together prior to
deployment, or by putting this information into a server-side (PHP, ASP, JSP, etc)
code comment block, as opposed to an HTML comment.
},
            },
            max_issues: 25
        }
    end

end
