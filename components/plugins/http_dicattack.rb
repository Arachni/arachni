=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.4
class Arachni::Plugins::HTTPDicattack < Arachni::Plugin::Base

    def prepare
        @url = framework.options.url.to_s

        @users   = File.read( options[:username_list] ).split( "\n" )
        @passwds = File.read( options[:password_list] ).split( "\n" )

        @found = false

        framework_pause
    end

    def run
        if !protected?( @url )
            print_info "The URL you provided doesn't seem to be protected."
            print_info 'Aborting...'
            return framework_resume
        end

        url = uri_parse( @url )

        print_status 'Building the request queue...'

        total_req = @users.size * @passwds.size
        print_status "Maximum number of requests to be transmitted: #{total_req}"

        @users.each do |user|
            @passwds.each do |pass|
                http.get( url.to_s, username: user, password: pass ).on_complete do |res|
                    next if @found

                    print_status "Username: '#{user}' -- Password: '#{pass}'"
                    next if res.code != 200

                    @found = true

                    print_ok "Found a match. Username: '#{user}' -- Password: '#{pass}'"
                    print_info "URL: #{res.url}"

                    framework.options.http.authentication_username = user
                    framework.options.http.authentication_password = pass

                    # register our findings...
                    register_results( 'username' => user, 'password' => pass )
                    http.abort
                end

            end
        end

        print_status 'Waiting for the requests to complete...'
        http.run
        print_bad "Couldn't find a match." if !@found
    end

    def clean_up
        framework_resume
    end

    def protected?( url )
        http.get( url, mode: :sync ).code == 401
    end

    def self.info
        {
            name:        'HTTP dictionary attacker',
            description: %q{
Uses wordlists to crack password protected directories.

If the cracking process is successful the found credentials will be set
framework-wide and used for the duration of the audit.

If that's not what you want, set the scope page-limit option to "0".
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.4',
            options:     [
                Options::Path.new( :username_list,
                    required:    true,
                    description: 'File with a list of usernames (newline separated).'
                ),
                Options::Path.new( :password_list,
                    required:    true,
                    description: 'File with a list of passwords (newline separated).'
                )
            ]
        }
    end

end
