=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Plugins::Default < Arachni::Plugin::Base

    def prepare
        @prepared = true
    end

    def run
        return if !@prepared
        @ran = true
    end

    def clean_up
        return if !@ran
        register_results( true )
    end

    def self.info
        {
            name:        'Default',
            description: %q{Some description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            options:     [
                Options::Int.new( 'int_opt', description: 'An integer.', default: 4 )
            ]
        }
    end

end
