=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Automated login plugin.
#
# It looks for the login form in the user provided URL, merges its input field
# with the user supplied parameters and sets the cookies of the response as
# framework-wide cookies.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
class Arachni::Plugins::AutoLogin < Arachni::Plugin::Base

    STATUSES  = {
        ok:             'Form submitted successfully.',
        form_not_found: 'Could not find a form suiting the provided parameters.',
        check_failed:   'Form submitted but the response did not match the verifier.'
    }

    def prepare
        framework.pause
        print_info 'System paused.'

        @parameters = form_parse_request_body( options[:parameters] )
        @verifier   = Regexp.new( options[:check] )
        @url        = options[:url].to_s
        @errored    = false
    end

    def run
        session.configure( url: @url, inputs: @parameters )

        response = begin
            session.login
        rescue Session::Error::FormNotFound
            register_results(
                'status'  => 'form_not_found',
                'message' => STATUSES[:form_not_found]
            )
            print_error STATUSES[:form_not_found]
            @errored = true
            return
        end

        framework.options.login.check_url     = response.url
        framework.options.login.check_pattern = @verifier

        if !session.logged_in?
            register_results(
                'status'  => 'check_failed',
                'message' => STATUSES[:check_failed]
            )
            print_error STATUSES[:check_failed]
            @errored = true
            return
        end

        cookies = http.cookies.inject({}){ |h, c| h.merge!( c.simple ) }

        register_results(
            'status'  =>  'ok',
            'message' => STATUSES[:ok],
            'cookies' => cookies
        )
        print_ok STATUSES[:ok]

        print_info 'Cookies set to:'
        cookies.each do |name, val|
            print_info "    * #{name.inspect} = #{val.inspect}"
        end
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
                merges its input fields with the user supplied parameters and sets
                the cookies of the response and request as framework-wide cookies.
            },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            options:     [
                Options::String.new( :url,
                    required:    true,
                    description: 'The URL that contains the login form.'
                ),
                Options::String.new( :parameters,
                    required:    true,
                    description: 'Form parameters to submit. ( username=user&password=pass )'
                ),
                Options::String.new( :check,
                    required:    true,
                    description:
                        'A pattern which will be used to verify a successful login.
                        For example, if a logout link only appears when a user is ' +
                        'logged in then it can be a perfect choice.'
                )
            ],
            priority:    0 # run before any other plugin
        }
    end

end
