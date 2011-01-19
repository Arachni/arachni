=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

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
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
# @see http://en.wikipedia.org/wiki/Cross-site_request_forgery
# @see http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)
# @see http://www.cgisecurity.com/csrf-faq.html
# @see http://cwe.mitre.org/data/definitions/352.html
#
class CSRF < Arachni::Module::Base

    def initialize( page )
        super( page )
    end

    def prepare( )

        # the Trainer can provide modules access to the HTML parser
        # and other cool stuff for element comparison
        @__trainer = @http.trainer

        # since we bypass the Auditor we must also do our own audit tracking
        @@__audited ||= []
    end

    def run( )

        print_status( 'Looking for CSRF candidates...' )

        print_status( 'Simulating logged-out user.' )

        # setup opts with empty cookies
        opts = {
            :headers => {
                'cookie'  => ''
            }
        }

        # request page without cookies, simulating a logged-out user
        @http.get( @page.url, opts ).on_complete {
            |res|

            # set-up the parser with the proper url so that it
            # can fix broken 'action' attrs and the like
            @__trainer.parser.url = res.effective_url.clone

            # extract forms from the body of the response
            forms_logged_out = @__trainer.parser.forms( res.body ).reject {
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

        if( query = URI( form.action ).query )
            # and we also need to check for a token in the form action
            action_splits = URI( form.action ).query.split( '=' )
            form.simple['auditable'].to_a.flatten.each {
                |str|
                next if !str
                found_token = true  if( csrf_token?( str ) )
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

        url  = form.action
        name = form.raw['attrs']['name'] || form.raw['attrs']['id'] || 'n/a'

        if @@__audited.include?( "#{url}::#{name}" )
            print_info( 'Skipping already audited form with name \'' +
                name + '\' of url: ' + url )
            return
        end

        @@__audited << "#{url}::#{name}"

        # append the result to the results array
        issue = Issue.new( {
            :var          => name,
            :url          => url,
            :injected     => 'n/a',
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::FORM,
            :response     => @page.html,
            :headers      => {
                :request    => 'n/a',
                :response   => 'n/a',
            }
        }.merge( self.class.info ) )

        print_ok( "Found unprotected form with name '#{name}' at '#{url}'" )
        register_results( [ issue ] )
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
            :author         => 'zapotek',
            :version        => '0.1',
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
