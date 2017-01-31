=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Plugins::Suspendable < Arachni::Plugin::Base

    attr_reader :counter

    def prepare
        @counter = 0
    end

    def restore( counter )
        @counter = counter
    end

    def run
        options[:my_option] = 'updated'
        @counter += 1

        wait_while_framework_running
    end

    def suspend
        @counter
    end

    def self.info
        {
            name:        'Suspendable',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            options:     [
                Options::String.new( 'my_option', required: true, description: 'Required option' )
            ]
        }
    end

end
