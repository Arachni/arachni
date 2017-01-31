=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.7
class Arachni::Plugins::FormDicattack < Arachni::Plugin::Base

    def prepare
        @url = framework.options.url

        @users   = File.read( options[:username_list] ).split( "\n" )
        @passwds = File.read( options[:password_list] ).split( "\n" )

        @user_field   = options[:username_field]
        @passwd_field = options[:password_field]

        @verifier = Regexp.new( options[:login_verifier] )

        @found = false

        framework_pause
    end

    def run
        form = session.find_login_form(
            url:    @url,
            inputs: [ @user_field, @passwd_field ]
        )
        if !form
            print_bad "Could not find a form suiting the provided params at: #{@url }"
            return
        end

        print_status "Found log-in form with name: #{form.name_or_id || '<n/a>'}"
        print_status 'Building the request queue...'

        total_req = @users.size * @passwds.size
        print_status "Number of requests to be performed: #{total_req}"

        # we need a clean cookie slate for each request
        opts = {
            no_cookie_jar:   true,
            update_cookies:  true,
            follow_location: false
        }

        @users.each do |user|
            @passwds.each do |pass|

                # merge the input fields of the form with our own params
                form.update( @user_field => user, @passwd_field => pass )
                form.submit( opts ) do |response|
                    next if @found

                    print_status "#{@user_field}: '#{user}' -- #{@passwd_field}: '#{pass}'"

                    next if !response.body.match( @verifier )

                    @found = true

                    print_ok "Found a match -- #{@user_field}: '#{user}'" +
                        " -- #{@passwd_field}: '#{pass}'"

                    # register our findings...
                    register_results( 'username' => user, 'password' => pass )
                    http.abort
                end

            end
        end

        print_status 'Waiting for the requests to complete...'
        http.run
        print_bad 'Couldn\'t find a match.' if !@found
    end

    def clean_up
        framework_resume
    end

    def self.info
        {
            name:        'Form dictionary attacker',
            description: %q{
Uses wordlists to crack login forms.

If the cracking process is successful the found credentials will be set
framework-wide and used for the duration of the audit.

If that's not what you want, set the scope page-limit option to "0".
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.7',
            options:     [
                Options::Path.new( :username_list,
                    required:    true,
                    description: 'File with a list of usernames (newline separated).'
                ),
                Options::Path.new( :password_list,
                    required:    true,
                    description: 'File with a list of passwords (newline separated).'
                ),
                Options::String.new( :username_field,
                    required:    true,
                    description: 'The name of the username form field.'
                ),
                Options::String.new( :password_field,
                    required:    true,
                    description: 'The name of the password form field.'
                ),
                Options::String.new( :login_verifier,
                    required:    true,
                    description:
                        'A regular expression which will be used to verify a successful login.
                        For example, if a logout link only appears when a user is ' +
                            'logged in then it can be a perfect choice.'
                )
            ]
        }
    end

end
