=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Plugins::Wait < Arachni::Plugin::Base

    def run
        wait_while_framework_running
        register_results( 'stuff' => true )
    end

    def self.info
        {
            name:        'Wait',
            description: %q{},
            tags:        ['wait_string', :wait_sym],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1'
        }
    end

end
