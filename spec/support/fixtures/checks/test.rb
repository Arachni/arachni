=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Checks::Test < Arachni::Check::Base

    def prepare
        @prepared = true
    end

    def run
        return if !@prepared
        @ran = true

        Arachni::HTTP::Client.get( "http://localhost/#{shortname}" ){}
    end

    def clean_up
        return if !@ran
        log_issue( vector: vector )
    end

    def vector
        v = Arachni::Element::Link.new( url: 'http://test.com', inputs: { stuff: 1 } )
        v.affected_input_name  = rand(9999).to_s + rand(9999).to_s
        v.affected_input_value = 2
        v.seed                 = 2
        v
    end

    def self.info
        {
            name:        'Test check',
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
                remedy_code:     ''
            }

        }
    end

end
