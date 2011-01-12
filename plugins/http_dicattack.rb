=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class HTTPDicattack < Arachni::Plugin::Base

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    def prepare
        @url     = @options['url']
        @users   = File.read( @options['userlist'] ).split( "\n" )
        @passwds = File.read( @options['passwdlist'] ).split( "\n" )
    end

    def run( )
        url = URI( @url )

        print_status( "Building the request queue..." )

        total_req = @users.size * @passwds.size
        print_status( "Number of requests to be transmitted: #{total_req}" )

        @users.each {
            |user|

            url.user = user
            @passwds.each {
                |pass|

                url.password = pass
                @framework.http.get( url.to_s ).on_complete {
                    |res|

                    print_status( "Username: '#{user}' -- Password: '#{pass}'" )
                    next if res.code != 200

                    print_ok( "Found a match. Username: '#{user}' -- Password: '#{pass}'" )
                    exit
                }

            }
        }

        print_status( "Waiting for the requests to complete..." )
        @framework.http.run
        print_error( "Couldn't find a match." )
        exit

    end

    def self.info
        {
            :name           => 'HTTP dictionary attacker',
            :description    => %q{Uses wordlists to crack password protected directories.
                It will exit the system once it finishes.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptUrl.new( 'url', [ true, 'URL of the protected directory.' ] ),
                Arachni::OptPath.new( 'userlist', [ true, 'List of usernames (newline separated).' ] ),
                Arachni::OptPath.new( 'passwdlist', [ true, 'List of passwords (newline separated).' ] )
            ]
        }
    end

end

end
end
