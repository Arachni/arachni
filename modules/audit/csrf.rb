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

module Arachni

module Modules

#
# Cross-Site Request Forgery audit module.
#
# It uses 4-pass reverse-diff analysis to determine which forms affect business logic
# and audits them for CSRF.
#
# Using this technique noise/false-positives should be kept to a minimum,
# however we do need to jump through some hoops.
#
# The technique used to identify which forms are CSRF worthy is described bellow.
#
# === 4-pass rDiff CSRF detection:
#
# * Request each page *without* cookies
#   * Extract forms.
# * Request each page *with* cookies
#   * Extract forms.
# * Check forms that appear *only* when logged-in for CSRF.
#
# In order for the module to give meaningful results a valid cookie-jar of a logged-in
# user must be supplied to the framework.
#
# However, as Arachni goes through the system it will gather
# cookies just like a user would, so if there are forms that only appear
# after a guest has performed a previous event it will check these too.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.2
#
# @see http://en.wikipedia.org/wiki/Cross-site_request_forgery
# @see http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)
# @see http://www.cgisecurity.com/csrf-faq.html
# @see http://cwe.mitre.org/data/definitions/352.html
#
class CSRF < Arachni::Module::Base

    def prepare

        # the Trainer can provide modules access to the HTML parser
        # and other cool stuff for element comparison
        @__trainer = @http.trainer

        # since we bypass the Auditor we must also do our own audit tracking
        @@__audited ||= Set.new
    end

    def run

        print_status( 'Looking for CSRF candidates...' )

        print_status( 'Simulating logged-out user.' )

        # setup opts with empty cookies
        opts = {
            :cookies => {},
            :remove_id => true
        }

        # request page without cookies, simulating a logged-out user
        @http.get( @page.url, opts ).on_complete {
            |res|

            # set-up the parser with the proper url so that it
            # can fix broken 'action' attrs and the like
            @parser = Arachni::Parser.new( Arachni::Options.instance, res )

            # extract forms from the body of the response
            forms_logged_out = @parser.forms( res.body ).reject {
                |form|
                form.auditable.empty?
            }

            print_status( "Found #{forms_logged_out.size.to_s} context irrelevant forms." )

            # get forms that are worthy of testing for CSRF
            # i.e. apper only when the user is logged-in
            csrf_forms = logged_in_only( forms_logged_out )

            print_status( "Found #{csrf_forms.size.to_s} CSRF candidates." )

            csrf_forms.each {
                |form|
                __log( form ) if unsafe?( form )
            }

        }

    end

    #
    # Tries to detect if a form is protected using an anti-CSRF token.
    #
    # @param  [Hash]  form
    #
    # @return   [Bool]  true if the form if vulnerable, false otherwise
    #
    def unsafe?( form )

        found_token = false

        # nobody says that tokens must be in a 'value' attribute,
        # they can just as well be in 'name'.
        # so we check them both...
        form.simple['auditable'].to_a.flatten.each_with_index {
            |str, i|
            next if !str
            next if !form.raw['auditable'][i]
            next if !form.raw['auditable'][i]['type']
            next if form.raw['auditable'][i]['type'].downcase != 'hidden'

            found_token = true if( csrf_token?( str ) )
        }

        link_vars = @parser.link_vars( form.action )
        if( !link_vars.empty? )
            # and we also need to check for a token in the form action
            link_vars.values.each {
                |val|
                next if !val
                found_token = true  if( csrf_token?( val ) )
            }
        end

        return !found_token
    end

    #
    # Returns forms that only appear when the user is logged-in.
    #
    # These are the forms that will most likely affect business logic.
    #
    # @param  [Array]  forms_logged_out  forms that appear while logged-out
    #                                      in order to eliminate them.
    #
    # @return  [Array]  forms to be checked for CSRF
    #
    def logged_in_only( logged_out )
        csrf_forms = []

        @page.forms.each {
            |form|

            next if form.auditable.size == 0

            if !( forms_include?( logged_out, form ) )
                csrf_forms << form
            end

        }

        return csrf_forms
    end

    def forms_include?( forms, form )

        forms.each {
            |i_form|

            if( form.id == i_form.id )
                return true
            end

        }

        return false
    end

    #
    # Checks if the str is an anti-CSRF token of base10/16/32/64.
    #
    # @param  [String]  str
    #
    def csrf_token?( str )

        # we could use regexps but i kinda like lcamtuf's (Michal's) way
        base16_len_min    = 8
        base16_len_max    = 45
        base16_digit_num  = 2

        base64_len_min    = 6
        base64_len_max    = 32
        base64_digit_num  = 1
        base64_case       = 2
        base64_digit_num2 = 3
        base64_slash_cnt  = 2

        len = str.size
        digit_cnt = str.scan(/[0-9]+/).join( '' ).size

        if( len >= base16_len_min &&
            len <= base16_len_max &&
            digit_cnt >= base16_digit_num
          )
            return true
        end

        upper_cnt = str.scan(/[A-Z]+/).join( '' ).size
        slash_cnt = str.scan(/\/+/).join( '' ).size

        if( len >= base64_len_min && len <= base64_len_max &&
            ( ( digit_cnt >= base64_digit_num && upper_cnt >= base64_case ) ||
              digit_cnt >= base64_digit_num2 ) &&
            slash_cnt <= base64_slash_cnt
          )

            return true
        end

        return false

    end


    def __log( form )
        return if !form.raw['attrs']

        url  = form.action
        name = form.raw['attrs']['name'] || form.raw['attrs']['id']

        if @@__audited.include?( "#{url}::#{name.to_s}" )
            print_info( 'Skipping already audited form with name \'' +
                name.to_s + '\' of url: ' + url )
            return
        end

        @@__audited << "#{url}::#{name}"

        log_issue(
            :var          => name,
            :url          => url,
            :elem         => Issue::Element::FORM,
            :response     => @page.html,
        )

        print_ok( "Found unprotected form with name '#{name}' at '#{url}'" )
    end

    def self.info
        {
            :name           => 'CSRF',
            :description    => %q{It uses 2-pass rDiff analysis to determine
                which forms affect business logic and audits them for CSRF.
                It requires a logged-in user's cookie-jar.},
            :elements       => [
                Issue::Element::FORM
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.2.2',
            :references     => {
                'Wikipedia' => 'http://en.wikipedia.org/wiki/Cross-site_request_forgery',
                'OWASP'     => 'http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)',
                'CGI Security' => 'http://www.cgisecurity.com/csrf-faq.html'
             },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Cross-Site Request Forgery},
                :description => %q{The web application does not, or can not,
                     sufficiently verify whether a well-formed, valid, consistent
                     request was intentionally provided by the user who submitted the request.
                     This is due to a lack of secure anti-CSRF tokens to verify
                     the freshness of the submitted data.},
                :tags        => [ 'csrf', 'rdiff', 'form', 'token' ],
                :cwe         => '352',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => %q{A unique token that guaranties freshness of submitted
                    data must be added to all web application elements that can affect
                    business logic.},
                :remedy_code => '',
            }

        }
    end

end
end
end
