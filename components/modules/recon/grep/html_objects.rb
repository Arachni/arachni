=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Looks for HTML "object" tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Modules::HTMLObjects < Arachni::Module::Base

    def self.regexp
        @regexp ||= /<object(.*)>(.*)<\/object>/im
    end

    def run
        match_and_log( self.class.regexp ) { |m| m && !m.empty? }
    end

    def self.info
        description = %q{Logs the existence of HTML object tags.
                Since Arachni can't execute things like Java Applets and Flash
                this serves as a heads-up to the penetration tester to review
                the objects in question using a different method.}
        {
            name:        'HTML objects',
            description: description,
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:        %q{HTML object},
                cwe:         '200',
                description: description,
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end

end
