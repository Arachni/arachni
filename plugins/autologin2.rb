=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
# Automated login plugin.
#
# It looks for the login form in the user provided URL,
# merges its input field with the user supplied parameters and sets the cookies
# of the response as framework-wide cookies to be used by the spider later on.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
class Arachni::Plugins::AutoLogin < Arachni::Plugin::Base

    MSG_SUCCESS     = 'Form submitted successfully.'
    MSG_FAILURE     = 'Could not find a form suiting the provided params at: '
    MSG_NO_RESPONSE = 'Form submitted but no response was returned.'

    def prepare
        framework.pause
        print_info 'System paused.'

        @params = parse_url_vars( '?' + options['params'] )
    end

    def run
        # grab the page containing the login form
        res = http.get( options['url'], async: false ).response

        # find the login form
        login_form = nil
        forms_from_response( res ).each { |form| login_form = form if login_form?( form ) }

        if !login_form
            register_results( code: 0, msg: MSG_FAILURE + options['url'] )
            print_bad MSG_FAILURE + options['url']
            return
        else
            print_info "Found fields: #{@uid_field}, #{@password_field}"
            @params.merge!(@uid_field => @params['user_name'], @password_field => @params['password'])
        end

        print_status "Found log-in form with name: #{login_form.name || '<n/a>'}"

        # merge the input fields of the form with the user supplied parameters
        login_form.update( @params )

        res = login_form.submit( async: false, update_cookies: true, follow_location: false ).response
        if !res
            register_results( code: -1, msg: MSG_NO_RESPONSE )
            print_bad MSG_NO_RESPONSE
            return
        end

        cookies = http.cookies.inject( {} ){ |h, c| h.merge!( c.simple ) } || {}

        register_results( code: 1, msg: MSG_SUCCESS, cookies: cookies.dup )
        print_ok MSG_SUCCESS

        print_info 'Cookies set to:'
        cookies.each_pair { |name, val| print_info( '    * ' + name + ' = ' + val ) }
    end

    def clean_up
        framework.resume
    end

    def login_form?( form )
#        @params.keys.each { |name| return false if !form.auditable.include?( name ) }
#        true
         @uid_field = find_uid_field( form )
 
         (@uid_field != nil && count_password_fields( form ) == 1)
    end
    
    def find_uid_field( form )
        require 'pp'
         form.raw['input'].each { |elem|
           return elem['name'] if elem['name'] =~ /.*[(login)(user)(id)(email)].*/ && elem['type'] == 'text'
         }
         nil
    end
    
    def count_password_fields( form )
      count=0
      form.raw['input'].each { |elem| 
        if elem['type'] == 'password'
          count += 1
          @password_field = elem['name']
        end
      }
      count
    end
    
    def self.info
        {
            name:        'AutoLogin2',
            description: %q{It looks for the login form in the user provided URL,
                merges its input fields with the user supplied parameters and sets the cookies
                of the response and request as framework-wide cookies to be used by the spider later on.
            },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>, Sunil Kumar <badboy16a@gmail.com>',
            version:     '0.1.0',
            options:     [
                Arachni::Component::Options::URL.new( 'url', [true, 'The URL that contains the login form.'] ),
                Arachni::Component::Options::String.new( 'params', [true, 'Form parameters to submit. ( username=user&password=pass )'] )
            ],
            order:       0 # run before any other plugin
        }
    end

end
