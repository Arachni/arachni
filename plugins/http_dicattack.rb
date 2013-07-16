=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::HTTPDicattack < Arachni::Plugin::Base

    def prepare
        # disable spidering and the subsequent audit
        # @framework.opts.link_count_limit = 0

        # don't scan the website just yet
        framework.pause
        print_info "System paused."

        @url = framework.opts.url.to_s

        @users   = File.read( options['username_list'] ).split( "\n" )
        @passwds = File.read( options['password_list'] ).split( "\n" )

        @found = false
    end

    def run
        if !protected?( @url )
            print_info "The URL you provided doesn't seem to be protected."
            print_info "Aborting..."
            return
        end

        url = uri_parse( @url )

        print_status "Building the request queue..."

        total_req = @users.size * @passwds.size
        print_status "Maximum number of requests to be transmitted: #{total_req}"

        @users.each do |user|
            url.user = user

            @passwds.each do |pass|
                url.password = pass.strip

                http.get( url.to_s ).on_complete do |res|
                    next if @found

                    print_status "Username: '#{user}' -- Password: '#{pass}'"
                    next if res.code != 200

                    @found = true

                    print_ok "Found a match. Username: '#{user}' -- Password: '#{pass}'"
                    print_info "URL: #{res.url}"

                    framework.opts.url = res.url

                    # register our findings...
                    register_results( username: user, password: pass )
                    http.abort
                end

            end
        end

        print_status "Waiting for the requests to complete..."
        http_run
        print_bad "Couldn't find a match."
    end

    def clean_up
        # continue with the scan
        framework.resume
    end

    def protected?( url )
        http.get( url, mode: :sync ).code == 401
    end

    def self.info
        {
            name:        'HTTP dictionary attacker',
            description: %q{Uses wordlists to crack password protected directories.
                If the cracking process is successful the found credentials will be set
                framework-wide and used for the duration of the audit.
                If that's not what you want set the crawler's link-count limit to "0".},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            options:     [
                Options::Path.new( 'username_list', [true, 'File with a list of usernames (newline separated).'] ),
                Options::Path.new( 'password_list', [true, 'File with a list of passwords (newline separated).'] )
            ]
        }
    end

end
