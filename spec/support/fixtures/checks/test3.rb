=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
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
