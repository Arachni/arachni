=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Checks::Test < Arachni::Check::Base

    def prepare
        @prepared = true
    end

    def run
        return if !@prepared
        @ran = true
    end

    def clean_up
        return if !@ran
        log_issue( url: 'http://blah', elem: 'link' )
    end

    def self.info
        {
            :name           => 'Test check',
            :description    => %q{Test description},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1',
            :references     => {
                'Wikipedia'  => 'http://en.wikipedia.org/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Test issue},
                :description => %q{Test description},
                :tags        => [ 'some', 'tag' ],
                :cwe         => '0',
                :severity    => Issue::Severity::HIGH,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Watch out!.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/blah'
            }

        }
    end

end
