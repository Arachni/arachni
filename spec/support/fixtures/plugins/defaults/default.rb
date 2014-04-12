=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            options:     [
                Options::Int.new( 'int_opt', description: 'An integer.', default: 4 )
            ]
        }
    end

end
