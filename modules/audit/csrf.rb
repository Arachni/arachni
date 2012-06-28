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
# In order for the module to give meaningful results, a valid cookie-jar of a logged-in
# user must be supplied to the framework.
#
# However, as Arachni goes through the system it will gather
# cookies just like a user would, so if there are forms that only appear
# after a guest has performed a previous event it will check these too.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3
#
# @see http://en.wikipedia.org/wiki/Cross-site_request_forgery
# @see http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)
# @see http://www.cgisecurity.com/csrf-faq.html
# @see http://cwe.mitre.org/data/definitions/352.html
#
class Arachni::Modules::CSRF < Arachni::Module::Base

    # since we bypass the Auditor we must also do our own audit tracking
    def self.audited
        @audited ||= Set.new
    end

    def run
        print_status 'Looking for CSRF candidates...'
        print_status 'Simulating logged-out user.'

        # request page without cookies, simulating a logged-out user
        http.get( page.url, cookies: {}, remove_id: true, no_cookiejar: true ) do |res|
            # extract forms from the body of the response
            logged_out = forms_from_response( res ).reject { |f| f.auditable.empty? }

            print_status "Found #{logged_out.size} context irrelevant forms."

            # get forms that are worthy of testing for CSRF i.e. appear only when the user is logged-in
            candidates = page.forms - logged_out

            print_status "Found #{candidates.size} CSRF candidates."

            candidates.each { |form| _log( form ) if unsafe?( form ) }
        end
    end

    #
    # Tries to detect if a form is protected using an anti-CSRF token.
    #
    # @param    [Arachni::Parser::Element::Form]  form
    #
    # @return   [Bool]  +true+ if the form has no anti-CSRF token, +false+ otherwise
    #
    def unsafe?( form )
        #
        # Nobody says that tokens must be in a +value+ attribute, they can
        # just as well be in +name+ -- so we check them both...
        #
        found_token = (form.raw['auditable'] || []).map do |input|
            next if !input['type'] || input['type'].downcase != 'hidden'
            csrf_token?( input['value'] ) || csrf_token?( input['name'] )
        end.include?( true )

        return false if found_token

        link_vars = parse_url_vars( form.action )
        if link_vars.any?
            # and we also need to check for a token in the form action.
            found_token = link_vars.to_a.flatten.
                map { |val| csrf_token?( val ) }.include?( true )
        end

        !found_token
    end

    #
    # Checks if the str is an anti-CSRF token of base10/16/32/64.
    #
    # @param  [String]  str
    #
    def csrf_token?( str )
        return false if !str

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
        digit_cnt = str.scan( /[0-9]+/ ).join.size

        if len >= base16_len_min && len <= base16_len_max && digit_cnt >= base16_digit_num
            return true
        end

        upper_cnt = str.scan( /[A-Z]+/ ).join.size
        slash_cnt = str.scan( /\/+/ ).join.size

        if len >= base64_len_min && len <= base64_len_max &&
            ((digit_cnt >= base64_digit_num && upper_cnt >= base64_case ) ||
              digit_cnt >= base64_digit_num2) && slash_cnt <= base64_slash_cnt
            return true
        end

        false
    end

    def _log( form )
        return if !form.raw['attrs']

        url  = form.action
        name = form.raw['attrs']['name'] || form.raw['attrs']['id']

        if self.class.audited.include?( "#{url}::#{name}" )
            print_info "Skipping already audited form '#{name}' at '#{url}'"
            return
        end

        self.class.audited << "#{url}::#{name}"

        log_issue( var: name, url: url, elem: Element::FORM, response: page.body )
        print_ok "Found unprotected form with name '#{name}' at '#{url}'"
    end

    def self.info
        {
            name:        'CSRF',
            description: %q{It uses 2-pass rDiff analysis to determine
                which forms affect business logic and audits them for CSRF.
                It requires a logged-in user's cookie-jar.},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3',
            references:  {
                'Wikipedia'    => 'http://en.wikipedia.org/wiki/Cross-site_request_forgery',
                'OWASP'        => 'http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)',
                'CGI Security' => 'http://www.cgisecurity.com/csrf-faq.html'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Request Forgery},
                description:     %q{The web application does not, or can not,
     sufficiently verify whether a well-formed, valid, consistent
     request was intentionally provided by the user who submitted the request.
     This is due to a lack of secure anti-CSRF tokens to verify
     the freshness of the submitted data.},
                tags:            %w(csrf rdiff form token),
                cwe:             '352',
                severity:        Severity::HIGH,
                cvssv2:          '',
                remedy_guidance: %q{A unique token that guaranties freshness of submitted
    data must be added to all web application elements that can affect
    business logic.},
                remedy_code:     ''
            }

        }
    end

end
