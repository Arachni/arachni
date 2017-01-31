=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Plugins::Distributable < Arachni::Plugin::Base

    is_distributable

    def run
        wait_while_framework_running
        register_results( 'stuff' => 1 )
    end

    def self.merge( results )
        { 'stuff' => results.map { |res| res['stuff'] }.inject( :+ ) }
    end

    def self.info
        {
            name:        'Distributable',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            issue:       {
                tags: [ 'distributable_string', :distributable_sym ]
            }
        }
    end

end
