=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Automated login plugin.
#
# It looks for the login form in the user provided URL,
# merges its input field with the user supplied parameters and sets the cookies
# of the response as framework-wide cookies to be used by the spider later on.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.6
class Arachni::Plugins::AutoLogin < Arachni::Plugin::Base

    MSG_SUCCESS     = 'Form submitted successfully.'
    MSG_FAILURE     = 'Could not find a form suiting the provided params at: '
    MSG_NO_RESPONSE = 'Form submitted but no response was returned.'
    MSG_NO_MATCH    = 'Form submitted but the response did not match the verifier.'

    def prepare
        framework.pause
        print_info 'System paused.'

        @params   = form_parse_request_body( options['params'] )
        @verifier = Regexp.new( options['check'] )

        @errored = false
    end

    def run
        # find the login form
        login_form = session.find_login_form( url: options['url'], inputs: @params.keys )

        if !login_form
            register_results( code: 0, msg: MSG_FAILURE + options['url'] )
            print_error MSG_FAILURE + options['url']
            @errored = true
            return
        end

        print_status "Found log-in form with name: #{login_form.name || '<n/a>'}"

        # merge the input fields of the form with the user supplied parameters
        login_form.update @params

        res = login_form.submit( mode: :sync, update_cookies: true, follow_location: false )
        if !res
            register_results( code: -1, msg: MSG_NO_RESPONSE )
            print_error MSG_NO_RESPONSE
            @errored = true
            return
        end

        check_url = res.url
        body = if res.redirection?
            check_url = to_absolute( res.headers.location )
            http.get( check_url, mode: :sync, update_cookies: true, follow_location: true ).body
        else
            res.body
        end

        if !body.match( @verifier )
            register_results( code: -2, msg: MSG_NO_MATCH )
            print_error MSG_NO_MATCH
            @errored = true
            return
        end

        session.login_form = login_form
        session.set_login_check check_url, @verifier

        cookies = http.cookies.inject( {} ){ |h, c| h.merge!( c.simple ) } || {}

        register_results( code: 1, msg: MSG_SUCCESS, cookies: cookies.dup )
        print_ok MSG_SUCCESS

        print_info 'Cookies set to:'
        cookies.each_pair { |name, val| print_info( '    * ' + name + ' = ' + val ) }
    end

    def clean_up
        if @errored
            print_info 'The scan will not progress, you can safely abort the process.'
            return
        end

        framework.resume
    end

    def self.info
        {
            name:        'AutoLogin',
            description: %q{It looks for the login form in the user provided URL,
                merges its input fields with the user supplied parameters and sets the cookies
                of the response and request as framework-wide cookies to be used by the spider later on.
            },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6',
            options:     [
                Options::URL.new( 'url', [true, 'The URL that contains the login form.'] ),
                Options::String.new( 'params', [true, 'Form parameters to submit. ( username=user&password=pass )'] ),
                Options::String.new( 'check', [true, 'A pattern which will be used to verify a successful login.
                    For example, if a logout link only appears when a user is logged in then it can be a perfect choice.'] )
            ],
            priority:    0 # run before any other plugin
        }
    end

end
