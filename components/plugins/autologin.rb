=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Automated login plugin.
#
# It looks for the login form in the user provided URL, merges its input field
# with the user supplied parameters and sets the cookies of the response as
# framework-wide cookies.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2.1
class Arachni::Plugins::AutoLogin < Arachni::Plugin::Base

    STATUSES  = {
        ok:               'Logged in successfully.',
        form_not_found:   'Could not find a form suiting the provided parameters.',
        form_not_visible: 'The form was located but its DOM element is not ' <<
                              'visible and thus cannot be submitted.',
        check_failed:     'The response did not match the verifier.'
    }

    def prepare
        @parameters = request_parse_body( options[:parameters] )
        @verifier   = Regexp.new( options[:check] )
        @url        = options[:url].to_s

        session.configure( url: @url, inputs: @parameters )

        print_status 'Logging in, please wait.'

        response = begin
            session.login( true )
        rescue Arachni::Session::Error::FormNotFound
            register_results(
                'status'  => 'form_not_found',
                'message' => STATUSES[:form_not_found]
            )
            handle_error( :form_not_found )
            return clean_up
        rescue Arachni::Session::Error::FormNotVisible
            register_results(
                'status'  => 'form_not_visible',
                'message' => STATUSES[:form_not_visible]
            )
            handle_error( :form_not_visible )
            return
        end

        print_status "Form submitted successfully, checking the session's validity."

        framework.options.session.check_url     ||= response.url
        framework.options.session.check_pattern ||= @verifier

        if !session.logged_in?
            register_results(
                'status'  => 'check_failed',
                'message' => STATUSES[:check_failed]
            )
            handle_error( :check_failed )
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

    def handle_error( type )
        print_error STATUSES[type]

        print_info 'Aborting the scan.'
        framework_abort
    end

    def self.info
        {
            name:        'AutoLogin',
            description: %q{
It looks for the login form in the user provided URL, merges its input fields
with the user supplied parameters and sets the cookies of the response and
request as framework-wide cookies.

**NOTICE**: If the login form is by default hidden and requires a sequence of DOM
interactions in order to become visible, this plugin will not be able to submit it.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.1',
            options:     [
                Options::String.new( :url,
                    required:    true,
                    description: 'The URL that contains the login form.'
                ),
                Options::String.new( :parameters,
                    required:    true,
                    description: 'Form parameters to submit -- special characters' +
                                 ' need to be URL encoded.( username=user&password=pass )'
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
