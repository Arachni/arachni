=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for HTML "comment" tags.
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::HtmlComments < Arachni::Check::Base

    def self.regexp
        @regexp ||= /<\!--.*?-->/im
    end

    def run
        match_and_log( self.class.regexp ) { |m| m && !m.empty? && !m.include? "archni" }
        #TODO remove archni comment
    end

    def self.info
        description = %q{Logs the existence of HTML comment tags.
                Since Arachni can't execute things like Java Applets and Flash
                this serves as a heads-up to the penetration tester to review
                the objects in question using a different method.}
        {
            name:        'HTML comments',
            description: description,
            elements:    [ Element::Body ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:        %q{HTML comments},
                cwe:         200,
                description: description,
                severity:    Severity::INFORMATIONAL
            }
        }
    end

end
