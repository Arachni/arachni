=begin
  $Id$

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
# @version: 0.1-pre
#
module Auditor
    
    @@audited ||= []
    
    #
    # Audits HTTP request headers injecting the injection_str as values
    # and then matching the response body against the id_regex.
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
    def audit_headers( injection_str, id_regex = nil, id = nil, &block )

        results = []
        
        # iterate through header fields and audit each one
        inject_each_var( get_request_headers( true ), injection_str ).each {
            |vars|

            audit_id = "#{self.class.info['Name']}:" +
                "#{@page.url}:#{Vulnerability::Element::HEADER}:" +
                "#{vars['altered'].to_s}=#{vars['hash'].to_s}"
            
            next if @@audited.include?( audit_id )

            # tell the user what we're doing
            print_status( "Auditing header field '" +
                vars['altered'] + "' of " + @page.url )
            
            # audit the url vars
            res = @http.header( @page.url, vars['hash'] )
            @@audited << audit_id

            # something might have gone bad,
            # make sure it doesn't ruin the rest of the show...
            if !res then next end
            
            # call the passed block
            if block_given?
                block.call( @page.url, res, vars['altered'] )
                next
            end
            
            if !res.body then next end
            
            # get matches
            result = get_matches( Vulnerability::Element::HEADER,
                vars['altered'], res, injection_str, id_regex, id, @page.url )
            
            # and append them to the results array
            results << result if result
        }

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
    def audit_links( injection_str, id_regex = nil, id = nil, &block )

        results = []
        
        work_on_links {
            |link|
            
            url       = link['href']
            link_vars = link['vars']
                
            # if we don't have any auditable elements just return
            if !link_vars then next end

            # iterate through all url vars and audit each one
            inject_each_var( link_vars, injection_str ).each {
                |vars|
    
                audit_id = "#{self.class.info['Name']}:" +
                    "#{url}:#{Vulnerability::Element::LINK}:" +
                    "#{vars['altered'].to_s}=#{vars['hash'].to_s}"
                
                next if @@audited.include?( audit_id )

                # tell the user what we're doing
                print_status( "Auditing link var '" +
                    vars['altered'] + "' of " + url )
                
                # audit the url vars
                res = @http.get( url, vars['hash'] )
                @@audited << audit_id
                
                # something might have gone bad,
                # make sure it doesn't ruin the rest of the show...
                if !res then next end
                
                # call the passed block
                if block_given?
                    block.call( url, res, vars['altered'] )
                    next
                end
                
                if !res.body then next end
                
                # get matches
                result = get_matches( Vulnerability::Element::LINK,
                    vars['altered'], res, injection_str, id_regex, id, url )
                
                # and append them to the results array
                results << result if result
            }
        }    

        results
    end

    #
    # Audits forms injecting the injection_str as value for the
    # variables and then matching the response body against the id_regex.
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
    def audit_forms( injection_str, id_regex = nil, id = nil, &block )
        
        results = []
        
        work_on_forms {
            |orig_form|
            form = get_form_simple( orig_form )

            next if !form
            
            url    = form['attrs']['action']
            method = form['attrs']['method']
                
            # iterate through each auditable element
            inject_each_var( form['auditable'], injection_str ).each {
                |input|

                audit_id = "#{self.class.info['Name']}:" +
                    "#{url}:" +
                    "#{Vulnerability::Element::FORM}:" + 
                    "#{input['altered'].to_s}=#{input['hash'].to_s}"
                
                next if @@audited.include?( audit_id )
                
                # inform the user what we're auditing
                print_status( "Auditing form input '" +
                    input['altered'] + "' with action " + url )

                if( method != 'get' )
                    res = @http.post( url, input['hash'] )
                else
                    res = @http.get( url, input['hash'] )
                end
                
                @@audited << audit_id
                
                # make sure that we have a response before continuing
                if !res then next end
                
                # call the block, if there's one
                if block_given?
                    block.call( url, res, input['altered'] )
                    next
                end

                if !res.body then next end
            
                # get matches
                result = get_matches( Vulnerability::Element::FORM,
                    input['altered'], res, injection_str, id_regex, id, url )
                
                # and append them to the results array
                results << result if result
            }
        }
        results
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
    def audit_cookies( injection_str, id_regex = nil, id = nil, &block )
        
        results = []
        
        # iterate through each cookie
        work_on_cookies {
            |orig_cookie|
        inject_each_var( get_cookie_simple( orig_cookie ), injection_str ).each {
            |cookie|

            next if Options.instance.exclude_cookies.include?( cookie['altered'] )
            
            audit_id = "#{self.class.info['Name']}:" +
                "#{@page.url}:#{Vulnerability::Element::COOKIE}:" +
                "#{cookie['altered'].to_s}=#{cookie['hash'].to_s}"
            
            next if @@audited.include?( audit_id )

            # tell the user what we're auditing
            print_status( "Auditing cookie '" +
                cookie['altered'] + "' of " + @page.url )

            # make a get request with our cookies
            res = @http.cookie( @page.url, cookie['hash'], nil )
                
            @@audited << audit_id

            # check for a response
            if !res then next end
            
            if block_given?
                block.call( @page.url, res, cookie['altered'] )
                next
            end
            
            if !res.body then next end
                
            # get possible matches
            result = get_matches( Vulnerability::Element::COOKIE,
                cookie['altered'], res, injection_str, id_regex, id, @page.url )
            # and append them
            results << result if result
        }
        }

        results
    end

    def get_matches( where, var, res, injection_str, id_regex, id, url )
        
        # fairly obscure condition...pardon me...
        if ( id && res.body.scan( id_regex )[0] == id ) ||
           ( !id && res.body.scan( id_regex )[0].size > 0 )
        
            print_ok( "In #{where} var #{var}" + ' ( ' + url + ' )' )
            
            print_verbose( "Injected str:\t" + injection_str )    
            print_verbose( "ID str:\t" + id )
            print_verbose( "Matched regex: " + id_regex.to_s )
            print_verbose( '---------' ) if only_positives?
    
            return {
                'var'          => var,
                'url'          => url,
                'injected'     => injection_str,
                'id'           => id,
                'regexp'       => id_regex.to_s,
                'regexp_match' => res.body.scan( id_regex ),
                'response'     => res.body,
                'elem'         => where,
                'headers'      => {
                    'request'    => get_request_headers( ),
                    'response'   => get_response_headers( res ),    
                }
            }
        end
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
    def inject_each_var( hash, to_inj )
        
        var_combo = []
        if( !hash || hash.size == 0 ) then return [] end
        
        # this is the original hash, in case the default values
        # are valid and present us with new attack vectors
        as_is = Hash.new( )
        as_is['altered'] = '__orig'
        chash = as_is['hash']    = hash.clone
            
        as_is['hash'].keys.each {
            |k|
            if( !as_is['hash'][k] ) then as_is['hash'][k] = '' end
        }
        var_combo << as_is
        
        # these are audit inputs, if a value is empty or null
        # we put a sample e-mail address in its place
        hash.keys.each {
            |k|
            
            hash = KeyFiller.fill( hash )
            
            var_combo << { 
                'altered' => k,
                'hash'    => hash.merge( { k => hash[k] + to_inj } )
            }
        }

        #
        # same as above but with null terminated injection strings
        #
        chash.keys.each {
            |k|
            
            chash = KeyFiller.fill( chash )
            
            var_combo << { 
                'altered' => k,
                'hash'    => chash.merge( { k => chash[k] + to_inj + "\0" } )
            }
        }

        
        var_combo
    end

end

end
end
