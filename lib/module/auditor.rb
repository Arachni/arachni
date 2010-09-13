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
# Includes audit methods.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
module Auditor
    
    #
    # holds audit identifiers
    #
    @@audited ||= []

    FORM_VALUES_ORIGINAL  = '__original_values__'
    FORM_VALUES_SAMPLE    = '__sample_values__'
    

    #
    # Holds constant bitfields that describe the preferred formatting
    # of injection strings. 
    #
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
    
    #
    # Holds constants that describe the HTML elements to be audited.
    #
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
        # Elements to audit.
        #
        # Only required when calling {#audit}.<br/>
        # If no elements have been passed to audit it will
        # use the elements in {#self.info}.
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
        # Formatting of the injection strings.
        #
        # A new set of audit inputs will be generated
        # for each value in the array.
        #
        # Values can be OR'ed bitfields of all available constants
        # of {Auditor::Format}. 
        #
        # @see  Auditor::Format
        #
        :format   => [ Format::STRAIGHT, Format::APPEND,
                       Format::NULL, Format::APPEND | Format::NULL ],
        
        #
        # If 'train' is set to true the HTTP response will be
        # analyzed for new elements. <br/>
        # Be carefull when enabling it, there'll be a performance penalty.
        #
        # When the Auditor submits a form with original or sample values
        # this option will be overriden to true.
        #
        :train    => false
    }
    
    #
    # Provides easy access to all audit methods.
    #
    # If no elements have been specified in 'opts' it will
    # use the elements in {#self.info}. <br/>
    # If no elements have been specified in 'opts' or {#self.info} it will
    # use the elements in {#OPTIONS}. <br/>
    #
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {#OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                    o HTTP response
    #                                    o name of the input vector
    #                                    o updated opts
    #                                    The block will be called as soon as
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit( injection_str, opts = { }, &block )
        
        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = self.class.info['Elements']
        end
        
        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = OPTIONS[:elements]
        end

        opts  = OPTIONS.merge( opts )
        
        results = []
        opts[:elements].each {
            |elem|
            
            case elem
              
                when  Element::LINK
                    results << audit_links( injection_str, opts, &block )
                  
                when  Element::FORM
                    results << audit_forms( injection_str, opts, &block )
                  
                when  Element::COOKIE
                    results << audit_cookies( injection_str, opts, &block )
                  
                when  Element::HEADER
                    results << audit_headers( injection_str, opts, &block )
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )
              
            end
          
        }
        
        return results.flatten
    end
    
    #
    # Audits HTTP header fields.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {#OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                    o HTTP response
    #                                    o name of the input vector
    #                                    o updated opts
    #                                    The block will be called as soon as
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_headers( injection_str, opts = { }, &block )
        
        return [] if !Options.instance.audit_headers
        
        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::HEADER
        url             = @page.url
        
        audit_id = audit_id( url, get_headers( ), opts, injection_str )
        return if audited?( audit_id )

        results = []
        # iterate through header fields and audit each one
        injection_sets( get_headers( ), injection_str, opts ).each {
            |vars|

            # inform the user what we're auditing
            print_status( get_status_str( url, vars, opts ) )
            
            # audit the url vars
            req = @http.header( @page.url, vars['hash'] )

            injected = vars['hash'][vars['altered']]
            on_complete( req, injected, vars, opts, &block )
            req.after_complete {
                |result|
                results << result.flatten[1] if result.flatten[1]
            }
        }
        audited( audit_id )
        
        results
    end
        
    #
    # Audits all the links found in the page.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {#OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                    o HTTP response
    #                                    o name of the input vector
    #                                    o updated opts
    #                                    The block will be called as soon as
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_links( injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::LINK

        results = []
        get_links.each {
            |link|
            
            next if !link
            
            url = URI( @page.url ).merge( URI( link['href'] ).path ).to_s
            link_vars = link['vars']
            
            # if we don't have any auditable elements just return
            if !link_vars then next end
            if link_vars.empty? then next end
              
            audit_id = audit_id( url, link_vars, opts, injection_str )
            next if audited?( audit_id )

            # iterate through all url vars and audit each one
            injection_sets( link_vars, injection_str, opts ).each {
                |vars|
    
                # inform the user what we're auditing
                print_status( get_status_str( url, vars, opts ) )
                
                # audit the url vars
                req = @http.get( url, vars['hash'], opts[:train] )
                
                injected = vars['hash'][vars['altered']]
                on_complete( req, injected, vars, opts, &block )
                req.after_complete {
                    |result|
                    results << result.flatten[1] if result.flatten[1]
                }
                
            }
            audited( audit_id )
        }
        
        results
    end

    #
    # Audits all the forms found in the page.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {#OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                    o HTTP response
    #                                    o name of the input vector
    #                                    o updated opts
    #                                    The block will be called as soon as
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_forms( injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::FORM
        
        results = []
        get_forms.each {
            |orig_form|
            
            form = get_form_simple( orig_form )

            next if !form
            
            url    = form['attrs']['action']
            method = form['attrs']['method']
            fields = form['auditable']
            
            audit_id = audit_id( url, fields, opts, injection_str )
            next if audited?( audit_id )

            # iterate through each auditable element
            injection_sets( fields, injection_str, opts ).each {
                |input|
                
                curr_opts = opts.dup
                if( input['altered'] == FORM_VALUES_ORIGINAL )
                    orig_id = audit_id( url, input['hash'], opts,
                      input['hash'].values | ["{#{FORM_VALUES_ORIGINAL}}"] )
                    next if audited?( orig_id )
                    audited( orig_id )
                    
                    print_debug( 'Submitting form with original values;' +
                        ' overriding trainer option.' )
                    opts[:train] = true
                    print_debug_trainer( opts )
                end

                if( input['altered'] == FORM_VALUES_SAMPLE )
                    sample_id = audit_id( url, input['hash'], opts,
                      input['hash'].values | ["{#{FORM_VALUES_SAMPLE}}"] )
                    next if audited?( sample_id )
                    audited( sample_id )
                    
                    print_debug( 'Submitting form with sample values;' +
                        ' overriding trainer option.' )
                    opts[:train] = true
                    print_debug_trainer( opts )
                end


                # inform the user what we're auditing
                print_status( get_status_str( url, input, opts ) )

                if( method != 'get' )
                    req = @http.post( url, input['hash'], opts[:train] )
                else
                    req = @http.get( url, input['hash'], opts[:train] )
                end
                opts = curr_opts.dup
                injected = input['hash'][input['altered']].to_s
                
                on_complete( req, injected, input, opts, &block )
                req.after_complete {
                    |result|
                    # ap result
                    results << result.flatten[1] if result.flatten[1]
                }
                
            }
            audited( audit_id )
        }
        
        return results
    end

    #
    # Audits page cookies.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {#OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                    o HTTP response
    #                                    o name of the input vector
    #                                    o updated opts
    #                                    The block will be called as soon as
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_cookies( injection_str, opts = { }, &block  )
        
        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::COOKIE
        url             = @page.url

        results = []
        get_cookies.each {
            |orig_cookie|
            
            cookie = get_cookie_simple( orig_cookie )
  
            audit_id = audit_id( url, cookie, opts, injection_str )
            next if audited?( audit_id )

            injection_sets( cookie, injection_str, opts ).each {
                |cookie|

                next if Options.instance.exclude_cookies.include?( cookie['altered'] )
            
                print_status( get_status_str( url, cookie, opts ) )

                req = @http.cookie( @page.url, cookie['hash'], nil )
                
                injected = cookie['hash'][cookie['altered']]
                on_complete( req, injected, cookie, opts, &block )
                req.after_complete {
                    |result|
                    results << result.flatten[1] if result.flatten[1]
                }
                
            }
            audited( audit_id )
        }
        
        # @http.run

        results
    end

    #
    # Registers a block to be executed as soon as the Typhoeus request (reg)
    # has been completed and a response has been received.
    #
    # If no &block has been provided {#get_matches} will be called instead. 
    # 
    # @param  [Typhoeus::Request]  req
    # @param  [String]  injected_str
    # @param  [Hash]  input  injection_sets() input set
    # @param  [Hash]  opts  an updated hash of options
    # @param  [Block]   &block         block to be passed the:
    #                                    o HTTP response
    #                                    o name of the input vector
    #                                    o updated opts
    #                                    The block will be called as soon as
    #                                    HTTP response is received.
    #
    def on_complete( req, injected_str, input, opts, &block )
        req.on_complete {
            |res |
            print_status( 'Analyzing response...' )
            
            # make sure that we have a response before continuing
            if !res then next end
                
            opts[:injected] = injected_str.to_s
            # call the block, if there's one
            if block_given?
                block.call( res, input['altered'], opts )
                next
            end
    
            if !res.body then next end
                
            # get matches
            get_matches( input['altered'], res.dup, injected_str, opts )
        }
    end

    #
    # Tries to identify a vulnerability through regexp pattern matching.
    #
    # If a vulnerability is found a message will be printed and a hash
    # will be returned describing the conditions under which
    # the vulnerability was discovered.
    #
    # @param  [String]  var  the name of the vulnerable input vector
    # @param  [Typhoeus::Response]
    # @param  [String]  injected_str
    # @param  [Hash]  opts
    #
    # @return  [Hash]
    #
    def get_matches( var, res, injected_str, opts )
        
        elem       = opts[:element]
        match      = opts[:match]
        regexp     = opts[:regexp]
        match_data = res.body.scan( regexp )[0]
        match_data = match_data.to_s
        
        # fairly obscure condition...pardon me...
        if ( match && match_data == match ) ||
           ( !match && match_data && match_data.size > 0 )
        
            url = res.effective_url
            print_ok( "In #{elem} var '#{var}' " + ' ( ' + url + ' )' )
            
            verified = match ? match : match_data
            print_verbose( "Injected string:\t" + injected_str )    
            print_verbose( "Verified string:\t" + verified )
            print_verbose( "Matched regular expression: " + regexp.to_s )
            print_verbose( '---------' ) if only_positives?
    
            res = {
                'var'          => var,
                'url'          => url,
                'injected'     => injected_str,
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
            
            @results << Vulnerability.new( res.merge( self.class.info ) )
            register_results( @results.uniq )
        end
    end
    
    #
    # Returns a status string that explaining what's happening.
    # 
    # The string contains the name of the input that is being audited
    # the url and the type of the input (form, link, cookie...)
    #
    # @param  [String]  url  the url under audit
    # @param  [Hash]  input
    # @param  [Hash]  opts
    #
    # @return  [String]
    #
    def get_status_str( url, input, opts )
        return "Auditing #{opts[:element]} variable '" +
          input['altered'] + "' of " + url 
    end
      
    #
    # Returns am audit identifier string to be registered using {#audited}.
    #
    # @param  [String]  url  the url under audit
    # @param  [Hash]  input
    # @param  [Hash]  opts
    #
    # @return  [String]
    #
    def audit_id( url, input, opts, injection_str )
        
        vars = input.keys.sort.to_s
        return "#{self.class.info['Name']}:" +
          "#{url}:" + "#{opts[:element]}:" + 
          "#{vars}=#{injection_str.to_s}"
    end
    
    #
    # Checks whether or not an audit has been already performed.
    #
    # @param  [String]  audit_id  a string returned by {#audit_id}
    #
    def audited?( audit_id )
      ret =  @@audited.include?( audit_id )
      
      msg = 'Current audit ID: ' if !ret
      msg = 'Skipping, already audited: ' if ret
      print_debug( msg + audit_id )
      
      return ret
    end
    
    #
    # Registers an audit
    #
    # @param  [String]  audit_id  a string returned by {#audit_id}
    #
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
    def injection_sets( hash, injection_str, opts = { } )
        
        var_combo = []
        if( !hash || hash.size == 0 ) then return [] end
        
        if( opts[:element] == Element::FORM )
            # this is the original hash, in case the default values
            # are valid and present us with new attack vectors
            as_is = Hash.new( )
            as_is['altered'] = FORM_VALUES_ORIGINAL
            as_is['hash'] = hash.dup
    
            as_is['hash'].keys.each {
                |k|
                if( !as_is['hash'][k] ) then as_is['hash'][k] = '' end
            }
            var_combo << as_is
            
            duphash = hash.dup
            arachni_defaults = Hash.new
            arachni_defaults['hash'] = hash.dup
            arachni_defaults['altered'] = FORM_VALUES_SAMPLE
            arachni_defaults['hash'] = KeyFiller.fill( duphash )
            var_combo << arachni_defaults
            
        end

        chash = hash.dup
        hash.keys.each {
            |k|

            hash = KeyFiller.fill( hash )
            opts[:format].each {
                |format|
                
                str  = format_str( injection_str, hash[k], format )
                
                var_combo << { 
                    'altered' => k,
                    'hash'    => hash.merge( { k => str } )
                }
                
            }
            
        }
        
        print_debug_injection_set( var_combo, opts )
        
        return var_combo
    end
    
    #
    # Prepares an injection string following the specified formating options
    # as contained in the format bitfield. 
    #
    # @see Format
    # @param  [String]  injection_str
    # @param  [String]  default_str  default value to be appended by the
    #                                 injection strig {#Format::APPEND} is
    #                                 set in 'format'
    # @param  [Integer]  format     bitfield describing formating preferencies
    #
    # @return  [String]
    #
    def format_str( injection_str, default_str, format  )
      
        null = append = ''

        null   = "\0"        if ( format & Format::NULL )     != 0
        append = default_str if ( format & Format::APPEND )   != 0
        append = null = ''   if ( format & Format::STRAIGHT ) != 0
                
        return append + injection_str + null
    end
    
    def print_debug_injection_set( var_combo, opts )
        return if !debug?
        
        print_debug( )
        print_debug_trainer( opts )
        print_debug_formatting( opts )
        print_debug_combos( var_combo )
    end
    
    def print_debug_formatting( opts )
        print_debug( '------------' )
        
        print_debug( 'Injection string format combinations set to:' )
        print_debug( '|')
        msg = []
        opts[:format].each {
            |format|
            
            if( format & Format::NULL ) != 0
                msg << 'null character termination (Format::NULL)'
            end
                
            if( format & Format::APPEND ) != 0
                msg << 'append to default value (Format::APPEND)'
            end
                
            if( format & Format::STRAIGHT ) != 0
                msg << 'straight, leave as is (Format::STRAIGHT)'
            end
            
            prep = msg.join( ' and ' ).capitalize + ". [Combo mask: #{format}]"
            prep.gsub!( 'format::null', "Format::NULL [#{Format::NULL}]" )
            prep.gsub!( 'format::append', "Format::APPEND [#{Format::APPEND}]" )
            prep.gsub!( 'format::straight', "Format::STRAIGHT [#{Format::STRAIGHT}]" )
            print_debug( "|----> " + prep )
            
            msg.clear
        }

    end
    
    def print_debug_combos( combos )
        print_debug( )
        print_debug( 'Prepared combinations:' )
        print_debug('|' )
        
        combos.each{
          |set|
          
          print_debug( '|' )
          print_debug( "|--> Auditing: " + set['altered'] )
          print_debug( "|--> Combo: " )
          
          set['hash'].each{
              |combo|
              print_debug( "|------> " + combo.to_s )
          }
          
        }
        
        print_debug( )
        print_debug( '------------' )
        print_debug( )

    end
    
    def print_debug_trainer( opts )
        print_debug( 'Trainer set to: ' + ( opts[:train] ? 'ON' : 'OFF' ) )
    end
    
end

end
end
