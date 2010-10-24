module Arachni

require Arachni::Options.instance.dir['lib'] + 'module/output'
require Arachni::Options.instance.dir['lib'] + 'module/key_filler'

module Element

class Auditable

    include Arachni::UI::Output

    alias :o_print_error    :print_error
    alias :o_print_status   :print_status
    alias :o_print_info     :print_info
    alias :o_print_ok       :print_ok
    alias :o_print_debug    :print_debug
    alias :o_print_verbose  :print_verbose
    alias :o_print_line     :print_line

    def print_error( str = '' )
        o_print_error( info[:name] + ": " + str )
    end

    def print_status( str = '' )
        o_print_status( info[:name] + ": " + str )
    end

    def print_info( str = '' )
        o_print_info( info[:name] + ": " + str )
    end

    def print_ok( str = '' )
        o_print_ok( info[:name] + ": " + str )
    end

    def print_debug( str = '' )
        o_print_debug( info[:name] + ": " + str )
    end

    def print_verbose( str = '' )
        o_print_verbose( info[:name] + ": " + str )
    end

    def print_line( str = '' )
        o_print_line( info[:name] + ": " + str )
    end


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
      # Apends the injection string to the default value of the input vector.<br/>
      # (If no default value exists Arachni will choose one.)
      #
      APPEND   = 1 << 1

      #
      # Terminates the injection string with a null character.
      #
      NULL     = 1 << 2

      #
      # Prefix the string with a ';', useful for command injection modules
      #
      SEMICOLON = 1 << 3
    end

    def auditor( auditor )
        @auditor = auditor
    end

    def http_request( url, opts )

    end

    def auditable

    end

    #
    # Audits all the selfs found in the page.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit( injection_str, opts = { }, &block )

        @@audited ||= []

        opts            = Arachni::Module::Auditor::OPTIONS.merge( opts )
        opts[:element]  = self.type

        opts[:injected_orig] = injection_str

        results = []

        # if we don't have any auditable elements just return
        return if auditable.empty?

        audit_id = audit_id( injection_str )
        return if !opts[:redundant] && audited?( audit_id )

        # iterate through all url vars and audit each one
        injection_sets( auditable, injection_str, opts ).each {
            |vars|

            # inform the user what we're auditing
            print_status( get_status_str( vars, opts ) )

            opts[:altered] = vars['altered']
            opts[:params]  = vars['hash']

            # audit the url vars
            req = http_request( @action, opts )
            return if !req

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

    # impersonate the auditor
    def info
        @auditor ? @auditor.class.info : { :name => '' }
    end


    private

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
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    def on_complete( req, injected_str, input, opts, &block )

        if( !opts[:async] )

            if( req && req.response )
                block.call( req.response, input['altered'], opts )
            end

            return
        end

        req.on_complete {
            |res|

            # make sure that we have a response before continuing
            if !res
                print_error( 'Failed to get responses, backing out... ' )
                next
            else
                print_status( 'Analyzing response #' + res.request.id.to_s + '...' )
            end

            opts[:injected] = injected_str.to_s
            opts[:combo]    = input
            # call the block, if there's one
            if block_given?
                block.call( res, input['altered'], opts )
                next
            end

            next if !res.body

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

        verification = false

        # an annoying encoding exception may be thrown by scan()
        # the sob started occuring again....
        begin
            if( @page.html.scan( regexp )[0] )
                verification = true
            end
        rescue

        end

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
                :var          => var,
                :url          => url,
                :injected     => injected_str,
                :id           => match.to_s,
                :regexp       => regexp.to_s,
                :regexp_match => match_data,
                :response     => res.body,
                :elem         => elem,
                :method       => res.request.method.to_s,
                :verification => verification,
                :opts         => opts.dup,
                :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,
                }
            }

            @results ||= []
            @results << Vulnerability.new( res.merge( @auditor.class.info ) )
            Arachni::Module::Registry.register_results( @results.uniq )
        end
    end

    #
    # Returns am audit identifier string to be registered using {#audited}.
    #
    # @param  [Hash]  input
    # @param  [Hash]  opts
    #
    # @return  [String]
    #
    def audit_id( injection_str )
        vars = auditable.keys.sort.to_s

        return "#{@auditor.class.info[:name]}:" +
          "#{@action}:" + "#{self.type}:" +
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
    def get_status_str( input, opts )
        return "Auditing #{self.type} variable '" +
          input['altered'] + "' of " + @action
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

        if( self.is_a? Arachni::Parser::Element::Form )
            # this is the original hash, in case the default values
            # are valid and present us with new attack vectors
            as_is = Hash.new( )
            as_is['altered'] = Arachni::Parser::Element::Form::FORM_VALUES_ORIGINAL
            as_is['hash'] = hash.dup

            as_is['hash'].keys.each {
                |k|
                if( !as_is['hash'][k] ) then as_is['hash'][k] = '' end
            }
            var_combo << as_is

            duphash = hash.dup
            arachni_defaults = Hash.new
            arachni_defaults['hash'] = hash.dup
            arachni_defaults['altered'] = Arachni::Parser::Element::Form::FORM_VALUES_SAMPLE
            arachni_defaults['hash'] = Arachni::Module::KeyFiller.fill( duphash )
            var_combo << arachni_defaults

        end

        chash = hash.dup
        hash.keys.each {
            |k|

            hash = Arachni::Module::KeyFiller.fill( hash )
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
    #                                 injection string if {Format::APPEND} is set in 'format'
    # @param  [Integer]  format     bitfield describing formating preferencies
    #
    # @return  [String]
    #
    def format_str( injection_str, default_str, format  )

        semicolon = null = append = ''

        null   = "\0"        if ( format & Format::NULL )     != 0
        semicolon   = ';'    if ( format & Format::SEMICOLON )   != 0
        append = default_str if ( format & Format::APPEND )   != 0
        semicolon = append = null = ''   if ( format & Format::STRAIGHT ) != 0


        return semicolon + append + injection_str + null
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
