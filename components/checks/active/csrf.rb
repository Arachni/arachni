=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Cross-Site Request Forgery check.
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
# In order for the check to give meaningful results, a valid cookie-jar of a logged-in
# user must be supplied to the framework.
#
# However, as Arachni goes through the system it will gather
# cookies just like a user would, so if there are forms that only appear
# after a guest has performed a previous event it will check these too.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://en.wikipedia.org/wiki/Cross-site_request_forgery
# @see https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)
# @see http://www.cgisecurity.com/csrf-faq.html
# @see http://cwe.mitre.org/data/definitions/352.html
class Arachni::Checks::CSRF < Arachni::Check::Base

    def run
        print_status 'Looking for CSRF candidates...'
        print_status 'Simulating logged-out user.'

        # request page without cookies, simulating a logged-out user
        http.get( page.url, cookies: {}, no_cookie_jar: true ) do |res|
            # extract forms from the body of the response
            logged_out = forms_from_response( res ).reject { |f| f.inputs.empty? }

            print_status "Found #{logged_out.size} context irrelevant forms."

            # get forms that are worthy of testing for CSRF i.e. appear only when the user is logged-in
            candidates = page.forms - logged_out

            print_status "Found #{candidates.size} CSRF candidates."

            candidates.each { |form| _log( form ) if unsafe?( form ) }
        end
    end

    # Tries to detect if a form is protected using an anti-CSRF token.
    #
    # @param    [Arachni::Element::Form]  form
    #
    # @return   [Bool]
    #   `true` if the form has no anti-CSRF token, `false` otherwise
    def unsafe?( form )
        # If a form has a nonce then we're cool, bail out early
        return false if form.has_nonce?

        # If the form has no source then it was dynamically provided by some
        # component, so skip them.
        return false if !form.source

        #
        # Nobody says that tokens must be in a +value+ attribute, they can
        # just as well be in +name+ -- so we check them both...
        #
        found_token = (form.inputs || []).map do |k, v|
            csrf_token?( v ) || csrf_token?( k )
        end.include?( true )

        return false if found_token

        link_vars = uri_parse_query( form.action )
        if link_vars.any?
            # and we also need to check for a token in the form action.
            found_token = link_vars.to_a.flatten.
                map { |val| csrf_token?( val ) }.include?( true )
        end

        !found_token
    end

    # Checks if the str is an anti-CSRF token of base10/16/32/64.
    #
    # @param  [String]  str
    def csrf_token?( str )
        return false if !str
        return true if str.to_s.include?( 'csrf' )

        # we could use regexps but i kinda like lcamtuf's (Michal's) way
        base16_len_min    = 8
        base16_digit_num  = 2

        base64_len_min    = 6
        base64_digit_num  = 1
        base64_case       = 2
        base64_digit_num2 = 3
        base64_slash_cnt  = 2

        len = str.size
        digit_cnt = str.scan( /[0-9]+/ ).join.size

        if len >= base16_len_min && digit_cnt >= base16_digit_num
            return true
        end

        upper_cnt = str.scan( /[A-Z]+/ ).join.size
        slash_cnt = str.scan( /\/+/ ).join.size

        if len >= base64_len_min && slash_cnt <= base64_slash_cnt &&
            ((digit_cnt >= base64_digit_num && upper_cnt >= base64_case ) ||
                digit_cnt >= base64_digit_num2)
            return true
        end

        false
    end

    def _log( form )
        url  = form.action
        name = form.name_or_id

        if audited?( "#{url}::#{name}" )
            print_info "Skipping already audited form '#{name}' at '#{page.url}'"
            return
        end

        audited( "#{url}::#{name}" )

        log( vector: form, proof: form.source )
        print_ok "Found unprotected form with name '#{name}' at '#{page.url}'"
    end

    def self.info
        {
            name:        'CSRF',
            description: %q{
It uses differential analysis to determine which forms affect business logic and
checks them for lack of anti-CSRF tokens.

(Works best with a valid session.)
},
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.3.5',

            issue:       {
                name:            %q{Cross-Site Request Forgery},
                description:     %q{
In the majority of today's web applications, clients are required to submit forms
which can perform sensitive operations.

An example of such a form being used would be when an administrator wishes to
create a new user for the application.

In the simplest version of the form, the administrator would fill-in:

* Name
* Password
* Role (level of access)

Continuing with this example, Cross Site Request Forgery (CSRF) would occur when
the administrator is tricked into clicking on a link, which if logged into the
application, would automatically submit the form without any further interaction.

Cyber-criminals will look for sites where sensitive functions are performed in
this manner and then craft malicious requests that will be used against clients
via a social engineering attack.

There are 3 things that are required for a CSRF attack to occur:

1. The form must perform some sort of sensitive action.
2. The victim (the administrator the example above) must have an active session.
3. Most importantly, all parameter values must be **known** or **guessable**.

Arachni discovered that all parameters within the form were known or predictable
and therefore the form could be vulnerable to CSRF.

_Manual verification may be required to check whether the submission will then
perform a sensitive action, such as reset a password, modify user profiles, post
content on a forum, etc._
},
                references:  {
                    'Wikipedia'    => 'http://en.wikipedia.org/wiki/Cross-site_request_forgery',
                    'OWASP'        => 'https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)',
                    'CGI Security' => 'http://www.cgisecurity.com/csrf-faq.html'
                },
                tags:            %w(csrf rdiff form token),
                cwe:             352,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
Based on the risk (determined by manual verification) of whether the form submission
performs a sensitive action, the addition of anti-CSRF tokens may be required.

These tokens can be configured in such a way that each session generates a new
anti-CSRF token or such that each individual request requires a new token.

It is important that the server track and maintain the status of each token (in
order to reject requests accompanied by invalid ones) and therefore prevent
cyber-criminals from knowing, guessing or reusing them.

_For examples of framework specific remediation options, please refer to the references._
}
            }
        }
    end

end
