=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Checks::Test3 < Arachni::Check::Base

    prefer :test2

    def run
        Arachni::HTTP::Client.get( "http://localhost/#{shortname}" ){}
    end

    def self.info
        {
            name:        'Test3 check',
            description: %q{Test description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1',

            issue:       {
                name:            %q{Test issue},
                description:     %q{Test description},
                references:  {
                    'Wikipedia' => 'http://en.wikipedia.org/'
                },
                tags:            ['some', 'tag'],
                cwe:             '0',
                severity:        Issue::Severity::HIGH,
                remedy_guidance: %q{Watch out!.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/blah'
            }

        }
    end

end
