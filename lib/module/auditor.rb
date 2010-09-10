=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/key_filler'

module Arachni
module Module

#
# Auditor module
#
# Included by {Module::Base}.<br/>
# Includes audit methods used to attack a web page.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
module Auditor
    
    @@audited ||= []
        
    module Format
      
      #
      # Leaves the injection string as is.
      #
      STRAIGHT = 1 << 0
      
      #
      # Apends the injection string to the default value of the input vector.<br/>.
      # (If no default value exists Arachni will choose one.)
      #
      APPEND   = 1 << 1
      
      #
      # Terminates the injection string with a null character.
      #
      NULL     = 1 << 2
    end
    
    module Element
        LINK    = Vulnerability::Element::LINK
        FORM    = Vulnerability::Element::FORM
        COOKIE  = Vulnerability::Element::COOKIE
        HEADER  = Vulnerability::Element::HEADER
    end
    
    #
    # Default audit options.
    #
    OPTIONS = {
        
        #
        # Elements to audit
        #
        :elements => [ Element::LINK, Element::FORM,
                       Element::COOKIE, Element::HEADER ],
        
        #
        # The regular expression to match against the response body.
        #
        :regexp   => nil,
        
        #
        # Verify the matched string with this value.
        #
        :match    => nil,
        
        #
        # Formatting of the injection string.
        #
        :format   => [ Format::STRAIGHT, Format::APPEND,
                       Format::NULL, Format::APPEND | Format::NULL ]
    }
    
    def audit( injection_str, opts = { } )
        
        opts    = OPTIONS.merge( opts )
        
        results = []
        opts[:elements].each {
            |elem|
            
            case elem
              
                when  Element::LINK
                    results << audit_links( injection_str, opts )
                  
                when  Element::FORM
                    results << audit_forms( injection_str, opts )
                    
                when  Element::COOKIE
                    results << audit_cookies( injection_str, opts )
                    
                when  Element::HEADER
                    results << audit_headers( injection_str, opts )
                    
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )
              
            end
          
        }
        
        return results.flatten
    end
    
    #
    # Audits HTTP request headers injecting the injection_str as values
    # and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]  injection_str
    # @param    [Hash]    opts
    #
    # @param    [Block]   block to be executed right after the
    #                      request has been made.
    #                      It will be passed the currently audited
    #                      variable, the response and the url.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_headers( injection_str, opts = { }, &block )
        
        return [] if !Options.instance.audit_headers
        
        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::HEADER
        url             = @page.url
                
        results = []
        # iterate through header fields and audit each one
        inject_each_var( get_headers( ), injection_str, opts ).each {
            |vars|

            audit_id = audit_id( url, vars, opts )
            next if audited?( audit_id )
                
            # inform the user what we're auditing
            print_status( get_status_str( url, vars, opts ) )
            
            # audit the url vars
            req = @http.header( @page.url, vars['hash'] )
            audited( audit_id )
                
            on_complete( req, injection_str, vars, opts, &block )
            req.after_complete {
                |result|
                results << result.flatten[1] if result.flatten[1]
            }
        }
        
        @http.run

        results
    end
        
    #
    # Audits links injecting the injection_str as value for the
    # variables and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]     injection_str
    # @param    [String]     id_regex     regular expression string
    # @param    [String]     id  string to double check the id_regex
    #                            matched data
    #
    # @param    [Block]     block to be executed right after the
    #                            request has been made.
    #                            It will be passed the currently audited
    #                            variable, the response and the url.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_links( injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::LINK

        results = []
        work_on_links {
            |link|
            
            url = link['href']
            link_vars = link['vars']
            
            # if we don't have any auditable elements just return
            if !link_vars then next end

            # iterate through all url vars and audit each one
            inject_each_var( link_vars, injection_str, opts ).each {
                |vars|
    
                audit_id = audit_id( url, vars, opts )
                next if audited?( audit_id )
                
                # inform the user what we're auditing
                print_status( get_status_str( url, vars, opts ) )
                
                # audit the url vars
                req = @http.get( url, vars['hash'] )

                audited( audit_id )
                
                on_complete( req, injection_str, vars, opts, &block )
                req.after_complete {
                    |result|
                    results << result.flatten[1] if result.flatten[1]
                }
                
            }
        }
        
        @http.run

        results
    end

    #
    # Audits forms injecting the injection_str as value for the
    # variables and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]  injection_str
    # @param    [String]  params
    #
    # @param    [Block]   block to be executed right after the
    #                       request has been made.
    #                       It will be passed the currently audited
    #                       variable, the response and the url.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_forms( injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::FORM
        
        results = []
        work_on_forms {
            |orig_form|
            
            form = get_form_simple( orig_form )

            next if !form
            
            url    = form['attrs']['action']
            method = form['attrs']['method']
                
            # iterate through each auditable element
            inject_each_var( form['auditable'], injection_str, opts ).each {
                |input|

                audit_id = audit_id( url, input, opts )
                next if audited?( audit_id )
                
                # inform the user what we're auditing
                print_status( get_status_str( url, input, opts ) )

                if( method != 'get' )
                    req = @http.post( url, input['hash'] )
                else
                    req = @http.get( url, input['hash'] )
                end
                
                audited( audit_id )
                
                on_complete( req, injection_str, input, opts, &block )
                req.after_complete {
                    |result|
                    results << result.flatten[1] if result.flatten[1]
                }
                
            }
        }
        
        @http.run
        
        return results
    end

    #
    # Audits cookies injecting the injection_str as value for the
    # cookies and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]     injection_str
    # @param    [String]     id_regex     regular expression string
    # @param    [String]     id  string to double check the id_regex
    #                                matched data
    #
    # @param    [Block]     block to be executed right after the
    #                            request has been made.
    #                            It will be passed the currently audited
    #                            variable, the response and the url.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_cookies( injection_str, opts = { }, &block  )
        
        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::COOKIE
        url             = @page.url

        results = []
        work_on_cookies {
            |orig_cookie|
            
            cookie = get_cookie_simple( orig_cookie )
            inject_each_var( cookie, injection_str, opts ).each {
                |cookie|

                next if Options.instance.exclude_cookies.include?( cookie['altered'] )
            
                audit_id = audit_id( url, cookie, opts )
                next if audited?( audit_id )
                
                print_status( get_status_str( url, cookie, opts ) )

                req = @http.cookie( @page.url, cookie['hash'], nil )
                audited( audit_id )
                
                on_complete( req, injection_str, cookie, opts, &block )
                req.after_complete {
                    |result|
                    results << result.flatten[1] if result.flatten[1]
                }
                
            }
        }
        
        @http.run

        results
    end

    def get_matches( var, res, injection_str, opts )
        
        elem       = opts[:element]
        match      = opts[:match]
        regexp     = opts[:regexp]
        match_data = res.body.scan( regexp )[0]
        
        # fairly obscure condition...pardon me...
        if ( match && match_data == match ) ||
           ( !match && match_data && match_data.size > 0 )
        
            url = res.effective_url
            print_ok( "In #{elem} var '#{var}' " + ' ( ' + url + ' )' )
            
            print_verbose( "Injected string:\t" + injection_str )    
            print_verbose( "Verified string:\t" + match_data )
            print_verbose( "Matched regular expression: " + regexp.to_s )
            print_verbose( '---------' ) if only_positives?
    
            return {
                'var'          => var,
                'url'          => url,
                'injected'     => injection_str,
                'id'           => match.to_s,
                'regexp'       => regexp.to_s,
                'regexp_match' => match_data,
                'response'     => res.body,
                'elem'         => elem,
                'headers'      => {
                    'request'    => res.request.headers,
                    'response'   => res.headers,    
                }
            }
        end
    end

    def on_complete( req, injection_str, input, opts, &block )
        req.on_complete {
            |res |

            # make sure that we have a response before continuing
            if !res then next end
                
            # call the block, if there's one
            if block_given?
                block.call( res, input['altered'], opts )
                next
            end

            if !res.body then next end
            
            # get matches
            get_matches( input['altered'], res, injection_str, opts )
        }
    end

    def get_status_str( url, input, opts )
        return "Auditing #{opts[:element]} variable '" +
          input['altered'] + "' of " + url 
    end
      
    def audit_id( url, input, opts )
        return "#{self.class.info['Name']}:" +
          "#{url}:" + "#{opts[:element]}:" + 
          "#{input['altered'].to_s}=#{input['hash'].to_s}"
    end
    
    def audited?( audit_id )
      return @@audited.include?( audit_id )
    end
    
    def audited( audit_id )
        @@audited << audit_id
    end
    
    #
    # Iterates through a hash setting each value to to_inj
    # and returns an array of new hashes
    #
    # @param    [Hash]    hash    name=>value pairs
    # @param    [String]    to_inj    the string to inject
    #
    # @return    [Array]
    #
    def inject_each_var( hash, injection_str, opts = { } )
        
        var_combo = []
        if( !hash || hash.size == 0 ) then return [] end
        
        # this is the original hash, in case the default values
        # are valid and present us with new attack vectors
        as_is = Hash.new( )
        as_is['altered'] = '__orig'
        chash = as_is['hash'] = hash.dup

        as_is['hash'].keys.each {
            |k|
            if( !as_is['hash'][k] ) then as_is['hash'][k] = '' end
        }
        var_combo << as_is

        hash.keys.each {
            |k|
            opts[:format].each {
                |format|
                
                hash = KeyFiller.fill( hash )
                str  = prep_injection_str( injection_str, hash[k], format )
                
                var_combo << { 
                    'altered' => k,
                    'hash'    => hash.merge( { k => str } )
                }
            }
        }
        
        return var_combo
    end
    
    def prep_injection_str( injection_str, default_str, format  )
      
        null = append = ''

        null   = "\0"        if ( format & Format::NULL )     != 0
        append = default_str if ( format & Format::APPEND )   != 0
        append = null = ''   if ( format & Format::STRAIGHT ) != 0
                
        return append + injection_str + null
    end
    
end

end
end
