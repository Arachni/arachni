=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Checks::Wait < Arachni::Check::Base

    def run
        loop { sleep 1 }
    end

    def self.info
        {
            name:        'Wait check',
            description: %q{Test description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1',
            references:  {
                'Wikipedia' => 'http://en.wikipedia.org/'
            },
            targets:     { 'Generic' => 'all' },
            issue:       {
                name:            %q{Test issue},
                description:     %q{Test description},
                tags: %w(some tag),
                cwe:             '0',
                severity:        Severity::HIGH,
                cvssv2:          '0',
                remedy_guidance: %q{Watch out!.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/blah'
            }

        }
    end

end
