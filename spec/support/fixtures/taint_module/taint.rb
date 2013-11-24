=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Modules::Taint < Arachni::Module::Base

    def run
        audit '--seed', train: true
    end

    def self.info
        {
            name:        'Taint module',
            description: %q{Test description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
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
                cvssv2:          '0',
                remedy_guidance: %q{Watch out!.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/blah'
            }

        }
    end

end
