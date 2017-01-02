=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Plugins::Bad < Arachni::Plugin::Base

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

    def self.gems
        %w(foobar)
    end

    def self.info
        {
            name:        '',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1'
        }
    end

end
