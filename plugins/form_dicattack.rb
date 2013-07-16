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
# @version 0.1.4
#
class Arachni::Plugins::FormDicattack < Arachni::Plugin::Base

    def prepare
        # disable crawling and the subsequent audit
        # framework.opts.link_count_limit = 0

        # don't scan the website just yet
        framework.pause
        print_info 'System paused.'

        @url = framework.opts.url

        @users   = File.read( options['username_list'] ).split( "\n" )
        @passwds = File.read( options['password_list'] ).split( "\n" )

        @user_field   = options['username_field']
        @passwd_field = options['password_field']

        @verifier = Regexp.new( options['login_verifier'] )

        @found = false
    end

    def run
        form = session.find_login_form( url: @url, inputs: [ @user_field, @passwd_field ] )
        if !form
            print_bad "Could not find a form suiting the provided params at: #{@url }"
            return
        end

        name = form.raw['attrs']['name'] ? form.raw['attrs']['name'] : '<n/a>'
        print_status "Found log-in form with name: #{name}"

        print_status 'Building the request queue...'

        total_req = @users.size * @passwds.size
        print_status "Number of requests to be transmitted: #{total_req}"

        # we need a clean cookie slate for each request
        opts = {
            no_cookiejar:    true,
            update_cookies:  true,
            follow_location: false
        }

        @users.each do |user|
            @passwds.each do |pass|

                # merge the input fields of the form with our own params
                form.update( @user_field => user, @passwd_field => pass )
                form.submit( opts ) do |res|
                    next if @found

                    print_status "#{@user_field}: '#{res.request.parameters[@user_field]}'" +
                        " -- #{@passwd_field}: '#{res.request.parameters[@passwd_field]}'"

                    next if !res.body.match( @verifier )

                    @found = true

                    print_ok "Found a match -- #{@user_field}: '#{res.request.parameters[@user_field]}'" +
                        " -- #{@passwd_field}: '#{res.request.parameters[@passwd_field]}'"

                    # register our findings...
                    register_results( username: user, password: pass )
                    http.abort
                end

            end
        end

        print_status 'Waiting for the requests to complete...'
        http_run
        print_bad 'Couldn\'t find a match.' if !@found
    end

    def clean_up
        # continue with the scan
        framework.resume
    end

    def self.info
        {
            name:        'Form dictionary attacker',
            description: %q{Uses wordlists to crack login forms.
                If the cracking process is successful the found credentials will be set
                framework-wide and used for the duration of the audit.
                If that's not what you want set the crawler's link-count limit to "0".},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            options:     [
                Options::Path.new( 'username_list', [true, 'File with a list of usernames (newline separated).'] ),
                Options::Path.new( 'password_list', [true, 'File with a list of passwords (newline separated).'] ),
                Options::String.new( 'username_field', [true, 'The name of the username form field.'] ),
                Options::String.new( 'password_field', [true, 'The name of the password form field.'] ),
                Options::String.new( 'login_verifier', [true, 'A regular expression which will be used to verify a successful login.
                    For example, if a logout link only appears when a user is logged in then it can be a perfect choice.'] )
            ]
        }
    end

end
