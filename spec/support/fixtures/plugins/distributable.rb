=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            issue:       {
                tags: [ 'distributable_string', :distributable_sym ]
            }
        }
    end

end
