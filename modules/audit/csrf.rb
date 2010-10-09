=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

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
# * Request each page twice *without* cookies,
#   compare responses and ignore context irrelevant content using rdiff.
#   * Extract forms.
# * Request each page twice *with* cookies,
#   compare responses and ignore context irrelevant content using rdiff.
#   * Extract forms.
# * Check forms that appear *only* when logged-in for CSRF.
#
# In order for the module to give meaningful results a valid cookie-jar of a logged-in
# user must be supplied to the framework.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://en.wikipedia.org/wiki/Cross-site_request_forgery
# @see http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)
# @see http://www.cgisecurity.com/csrf-faq.html
# @see http://cwe.mitre.org/data/definitions/352.html
#
class CSRF < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )
    end

    def prepare( )
        
        # initialize the results array
        @results = []
        
        @__opts = {
            # this module is fairly complex as is,
            # so let's make it easier on us and work with sync requests
            :async       => false
        }
        
        # the Trainer can provide modules access to the HTML Analyzer
        # and other cool stuff for element comparison
        @__trainer = Arachni::Module::Trainer.instance
        
        # since we bypass the Auditor we must also do our own audit tracking
        @@__audited ||= []
    end
    
    def run( )
        
        print_status( 'Looking for CSRF candidates...' )
        
        print_status( 'Simulating logged-out user.' )
        forms_logged_out = __forms_logged_out( )
        
        print_status( "Found #{forms_logged_out.size.to_s} context irrelevant forms." )
        
        # get forms that are worthy of testing for CSRF
        # i.e. apper only when the user is logged-in
        csrf_forms = __csrf_forms( forms_logged_out )
        print_status( "Found #{csrf_forms.size.to_s} CSRF candidates." )
        
        csrf_forms.each {
            |form|
            __log( form ) if __audit( form )
        }
        
        register_results( @results )
    end
    
    #
    # Tries to detect if a form is protected using an anti-CSRF token.
    #
    # @param  [Hash]  form
    #
    # @return   [Bool]  true if the form if vulnerable, folse otherwise
    #
    def __audit( form )
      
        found_token = false
        
        # nobody says that tokens must be in a 'value' attribute,
        # they can just as well be in 'name'.
        # so we check them both...
        get_form_simple( form )['auditable'].to_a.flatten.each_with_index {
            |str, i|
            next if !str
            next if !form['auditable'][i]
            next if !form['auditable'][i]['type']
            next if form['auditable'][i]['type'].downcase != 'hidden'
            
            found_token = true if( __csrf_token?( str ) )
        }
        
        if( query = URI( form['attrs']['action'] ).query )
            # and we also need to check for a token in the form action
            action_splits = URI( form['attrs']['action'] ).query.split( '=' )
            get_form_simple( form )['auditable'].to_a.flatten.each {
                |str|
                next if !str
                found_token = true  if( __csrf_token?( str ) )
            }
        end
        
        return !found_token
    end
    
    #
    # Checks if the str is an anti-CSRF token of base10/16/32/64.
    #
    # @param  [String]  str
    #
    def __csrf_token?( str )
        
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
    
    # def __submit( form )
    #     
    #     form = get_form_simple( form )
    #     
    #     url    = form['attrs']['action']
    #     method = form['method']
    #     
    #     opts = {
    #         :params => Arachni::Module::KeyFiller.fill( form['auditable'] )
    #     }.merge( @__opts )
    #     
    #     if( method != 'get' )
    #         req = @http.post( url, opts )
    #     else
    #         req = @http.get( url, opts )
    #     end
    #     
    #     return req.response
    # end
    
    #
    # Returns forms that appear when the user is logged in.
    # 
    # The crawling process took place with logged-in cookies
    # so {#get_forms} will do just fine.
    #
    # @return   [Array]  forms
    #
    def __forms_logged_in
        return get_forms()
    end
    
    #
    # Simulates a logged-out user accessing the page and extracts 
    # forms from the HTML response.
    #
    # @return   [Array]  forms
    #
    def __forms_logged_out
        
        # setup opts with empty cookies
        opts = {
            :headers => {
                'cookie'  => ''
            }
        }.merge( @__opts )
        
        # request page without cookies, simulating a logged-out user
        res  = @http.get( @page.url, opts ).response
        
        # set-up the Analyzer with the proper url so that it
        # can fix broken 'action' attrs
        @__trainer.analyzer.url = res.effective_url.clone
        
        # extract forms from the body of the response
        return @__trainer.analyzer.get_forms( res.body ).clone
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
    def __csrf_forms( forms_logged_out )
        csrf_forms = []
        
        __forms_logged_in.each {
            |form|
            
            next if form['auditable'].size == 0
            
            if !( __forms_include?( forms_logged_out, form ) )
                csrf_forms << form
            end
            
        }
        
        return csrf_forms
    end
    
    def __forms_include?( forms, form )
        
        forms.each {
            |i_form|
            
            if( @__trainer.form_id( form ) == @__trainer.form_id( i_form ) )
                return true
            end
                    
        }
        
        return false
    end
    
    def __log( form )

        url  = form['attrs']['action']
        name = form['attrs']['name'] || 'n/a'
              
        if @@__audited.include?( "#{url}::#{name}" )
            print_info( 'Skipping already audited form with name \'' +
                name + '\' of url: ' + url )
            return
        end
        
        @@__audited << "#{url}::#{name}"
      
        # append the result to the results array
        @results << Vulnerability.new( {
            :var          => name,
            :url          => url,
            :injected     => 'n/a',
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Vulnerability::Element::FORM,
            :response     => @page.html,
            :headers      => {
                :request    => 'n/a',
                :response   => 'n/a',    
            }
        }.merge( self.class.info ) )
        
        print_ok( "Found unprotected form with name '#{name}' at '#{url}'" )
    end
    
    def self.info
        {
            :name           => 'CSRF',
            :description    => %q{It uses 2-pass rDiff analysis to determine
                which forms affect business logic and audits them for CSRF.
                It requires a logged-in user's cookie-jar.},
            :elements       => [
                Vulnerability::Element::FORM
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                'Wikipedia' => 'http://en.wikipedia.org/wiki/Cross-site_request_forgery',
                'OWASP'     => 'http://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)',
                'CGI Security' => 'http://www.cgisecurity.com/csrf-faq.html'
             },
            :targets        => { 'Generic' => 'all' },
                
            :vulnerability   => {
                :name        => %q{Cross-Site Request Forgery},
                :description => %q{The web application does not, or can not,
     sufficiently verify whether a well-formed, valid, consistent
     request was intentionally provided by the user who submitted the request. },
                :cwe         => '352',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
end
