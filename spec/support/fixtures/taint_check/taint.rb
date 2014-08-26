=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Checks::Taint < Arachni::Check::Base

    def run
        audit '--seed', submit: { train: true }
    end

    def self.info
        {
            name:        'Taint check',
            description: %q{Test description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            references:  {
                'Wikipedia' => 'http://en.wikipedia.org/'
            },
            targets:     { 'Generic' => 'all' },
            issue: {
                name:            %q{Test issue},
                description:     %q{Test description},
                tags:            %w(some tag),
                cwe:             '0',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Watch out!.},
                remedy_code:     ''
            }

        }
    end

end
