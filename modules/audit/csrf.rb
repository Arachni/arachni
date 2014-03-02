=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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
# @version 0.3.2
#
# @see http://en.wikipedia.org/wiki/Cross-site_request_forgery
# @see http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)
# @see http://www.cgisecurity.com/csrf-faq.html
# @see http://cwe.mitre.org/data/definitions/352.html
#
class Arachni::Modules::CSRF < Arachni::Module::Base

    def run
        print_status 'Looking for CSRF candidates...'
        print_status 'Simulating logged-out user.'

        # request page without cookies, simulating a logged-out user
        http.get( page.url, cookies: {}, no_cookiejar: true ) do |res|
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
    # @param    [Arachni::Element::Form]  form
    #
    # @return   [Bool]  +true+ if the form has no anti-CSRF token, +false+ otherwise
    #
    def unsafe?( form )
        # if a form has a nonce then we're cool, bail out early
        return false if form.has_nonce?

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

        if audited?( "#{url}::#{name}" )
            print_info "Skipping already audited form '#{name}' at '#{page.url}'"
            return
        end

        audited( "#{url}::#{name}" )

        log( var: name, elem: Element::FORM )
        print_ok "Found unprotected form with name '#{name}' at '#{page.url}'"
    end

    def self.info
        {
            name:        'CSRF',
            description: %q{It uses 2-pass rDiff analysis to determine
                which forms affect business logic and audits them for CSRF.
                It requires a logged-in user's cookie-jar.},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3.2',
            references:  {
                'Wikipedia'    => 'http://en.wikipedia.org/wiki/Cross-site_request_forgery',
                'OWASP'        => 'http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)',
                'CGI Security' => 'http://www.cgisecurity.com/csrf-faq.html',
                'WASC'         => 'http://projects.webappsec.org/w/page/13246919/Cross%20Site%20Request%20Forgery'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Request Forgery},
                description:     %q{In the majority of today's web applications, 
                    clients are required to submit forms. When these forms are 
                    submitted that contents within the form are typically 
                    processed by the server. An example of such a form is when 
                    an administrator wishes to create a new user for the 
                    application. In the simplest form the administrator would 
                    submit a form with the users Name, Password, and Role (level 
                    of access). Cross Site Request Forgery (CSRF) is where an 
                    administrator could be tricked into clicking on a link that 
                    if logged into the application would automatically submit 
                    the form without any further interaction. Cyber-criminals 
                    will look for sites where sensitive functions are performed 
                    in this vulnerable manner, and then craft malicious requests 
                    that will be used against clients in a social engineering 
                    attack. There are 3 things that are required for a CSRF 
                    attack to occur. 1. The form must perform a sensitive action 
                    2. The victim (admin the example above) must have an active 
                    session 3. Most importantly, all parameter values must be 
                    known or guessable. Arachni discovered that all parameters 
                    within the form were known or predictable, and therefore 
                    could be vulnerable to CSRF. Manual verification may be 
                    required to check whether the submission will then perform a 
                    sensitive action such as reset a password, modify user 
                    profiles, post content for a forum, etc.},
                tags:            %w(csrf rdiff form token),
                cwe:             '352',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Based on the risk determined by manual 
                    verification of whether the submission will then perform a 
                    sensitive action, it is recommended that the server utilise 
                    CSRF tokens. These can be configured in such a way that each 
                    session generates a new CSRF token or such that each 
                    individual request requires a new token. CSRF tokens are 
                    passed to the server as a normal parameter and not as a 
                    cookie value. It is equally important that the server track 
                    and maintain the status of each token, this will enable a 
                    server to reject any request that does not contain a valid 
                    token, and therefor prevent any cyber-criminal from knowing 
                    or guessing all parameter values. For examples of framework 
                    specific remediation, refer to the references.}
            }
        }
    end

end
