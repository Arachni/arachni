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

    def self.reset
        @@audited = []
    end

    attr_accessor :altered

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

    #
    # Callback invoked by {Arachni::Element::Auditable#audit} to submit
    # the object via {Arachni::Module::HTTP}.
    #
    # Must be implemented by the extending class.
    #
    # @param    [String]    url
    # @param    [Hash]      opts
    #
    # @see #submit
    #
    def http_request( url, opts )

    end

    def auditable

    end

    #
    # Submits self using {#http_request}.
    #
    # @param  [Hash]  opts
    #
    # @see #http_request
    #
    def submit( opts = {} )

        opts = Arachni::Module::Auditor::OPTIONS.merge( opts )
        opts[:params]  = auditable( )

        return http_request( @action, opts )
    end

    #
    # Audits self
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {Arachni::Module::Auditor#OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    def audit( injection_str, opts = { }, &block )

        # respect user audit options
        audit_opt = "@audit_#{self.type}s"
        return if !Arachni::Options.instance.instance_variable_get( audit_opt )

        @@audited ||= []

        opts            = Arachni::Module::Auditor::OPTIONS.merge( opts )
        opts[:element]  = self.type

        opts[:injected_orig] = injection_str

        # if we don't have any auditable elements just return
        return if auditable.empty?

        audit_id = audit_id( injection_str )
        return if !opts[:redundant] && audited?( audit_id )

        results = []
        # iterate through all variation and audit each one
        injection_sets( injection_str, opts ).each {
            |elem|

            altered = elem.altered

            opts[:altered] = altered.dup

            return if skip?( elem )

            # inform the user about what we're auditing
            print_status( get_status_str( altered ) )

            # submit the element with the injection values
            req = elem.submit( opts )
            return if !req

            injected = elem.auditable[altered]
            on_complete( req, injection_str, elem, opts, &block )
            req.after_complete {
                |result|
                results << result.flatten[1] if result.flatten[1]
            }
        }

        audited( audit_id )
    end

    def skip?( elem )
        return @auditor.skip?( elem )
    end

    #
    # Injectes the injecton_str in self's values according to formatting options
    # and returns an array of hashes in the form of:
    #  <altered_variable>   => <new element>
    #
    # @param    [String]  injection_str  the string to inject
    #
    # @return    [Array]
    #
    def injection_sets( injection_str, opts = { } )

        opts = Arachni::Module::Auditor::OPTIONS.merge( opts )
        hash = auditable( ).dup

        var_combo = []
        if( !hash || hash.size == 0 ) then return [] end

        if( self.is_a?( Arachni::Parser::Element::Form ) )

            if !audited?( audit_id( Arachni::Parser::Element::Form::FORM_VALUES_ORIGINAL ) )
                # this is the original hash, in case the default values
                # are valid and present us with new attack vectors
                elem = self.dup
                elem.altered = Arachni::Parser::Element::Form::FORM_VALUES_ORIGINAL
                var_combo << elem
            end

            if !audited?( audit_id( Arachni::Parser::Element::Form::FORM_VALUES_SAMPLE ) )
                duphash = hash.dup
                elem = self.dup
                elem.auditable = Arachni::Module::KeyFiller.fill( duphash )
                elem.altered = Arachni::Parser::Element::Form::FORM_VALUES_SAMPLE
                var_combo << elem
            end
        end

        chash = hash.dup
        hash.keys.each {
            |k|

            chash = Arachni::Module::KeyFiller.fill( chash )
            opts[:format].each {
                |format|

                str  = format_str( injection_str, chash[k], format )

                elem = self.dup
                elem.altered = k.dup
                elem.auditable = chash.merge( { k => str } )
                var_combo << elem
            }

        }

        print_debug_injection_set( var_combo, opts )

        return var_combo
    end


    # impersonate the auditor to the output methods
    def info
        @auditor ? @auditor.class.info : { :name => '' }
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
    def get_status_str( altered )
        return "Auditing #{self.type} variable '" + altered + "' of " + @action
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
    # @param  [Hash]    variation
    # @param  [Hash]    opts           an updated hash of options
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    def on_complete( req, injected_str, elem, opts, &block )

        altered = elem.altered
        combo   = elem.auditable
        opts[:injected] = injected_str.to_s
        opts[:combo]    = combo

        # ap opts
        if( !opts[:async] )

            if( req && req.response )
                block.call( req.response, opts )
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

            # call the block, if there's one
            if block_given?
                block.call( res, opts )
                next
            end

            next if !res.body

            # get matches
            get_matches( res.dup, opts )
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
    # @param  [Hash]  opts
    #
    # @return  [Hash]
    #
    def get_matches( res, opts )
        regexps    = [opts[:regexp]].flatten
        regexps.each{ |regexp| match_and_log( regexp, res, opts ) }
    end

    def match_and_log( regexp, res, opts )

        elem       = opts[:element]
        match      = opts[:match]
        var        = opts[:altered]

        match_data = res.body.scan( regexp )[0]
        match_data = match_data.to_s

        verification = false

        # an annoying encoding exception may be thrown by scan()
        # the sob started occuring again....
        begin
            if( @auditor.page.html.scan( regexp )[0] )
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
            injected = opts[:combo][var] ? opts[:combo][var] : '<n/a>'
            print_verbose( "Injected string:\t" + injected )
            print_verbose( "Verified string:\t" + verified )
            print_verbose( "Matched regular expression: " + regexp.to_s )
            print_debug( 'Request ID: ' + res.request.id.to_s )
            print_verbose( '---------' ) if only_positives?

            res = {
                :var          => var,
                :url          => url,
                :injected     => injected,
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
            Arachni::Module::Manager.register_results( @results.uniq )
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
          |elem|

          altered = elem.altered
          combo   = elem.auditable


          print_debug( '|' )
          print_debug( "|--> Auditing: " + altered )
          print_debug( "|--> Combo: " )

          combo.each {
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
