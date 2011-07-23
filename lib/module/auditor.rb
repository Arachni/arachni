=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module

#
# Auditor module
#
# Included by {Module::Base} and provides abstract audit methods.
#
# There are 3 main types of audit techniques available:
# * Pattern matching -- {#audit}
# * Timing attacks -- {#audit_timeout}
# * Differential analysis attacks -- {#audit_rdiff}
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.3
#
module Auditor

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

    #
    # Holds constants that describe the HTML elements to be audited.
    #
    module Element
        LINK    = Issue::Element::LINK
        FORM    = Issue::Element::FORM
        COOKIE  = Issue::Element::COOKIE
        HEADER  = Issue::Element::HEADER
        BODY    = Issue::Element::BODY
        PATH    = Issue::Element::PATH
        SERVER  = Issue::Element::SERVER
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
                       Element::COOKIE, Element::HEADER,
                       Issue::Element::BODY ],

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
        :train     => false,

        #
        # Enable skipping of already audited inputs
        #
        :redundant => false,

        #
        # Make requests asynchronously
        #
        :async     => true
    }

    #
    # Matches the HTML in @page.html to an array of regular expressions
    # and logs the results.
    #
    # @param    [Array<Regexp>]     regexps
    # @param    [String]            string
    # @param    [Block]             block       block to verify matches before logging
    #                                               must return true/false
    #
    def match_and_log( regexps, string = @page.html, &block )

        # make sure that we're working with an array
        regexps = [regexps].flatten

        elems = self.class.info[:elements]
        elems = OPTIONS[:elements] if !elems || elems.empty?

        regexps.each {
            |regexp|

            string.scan( regexp ).flatten.uniq.each {
                |match|

                next if !match
                next if block && !block.call( match )

                log(
                    :regexp  => regexp,
                    :match   => match,
                    :element => Issue::Element::BODY
                )
            } if elems.include? Issue::Element::BODY

            next if string == @page.html

            @page.response_headers.each {
                |k,v|
                next if !v

                v.to_s.scan( regexp ).flatten.uniq.each {
                    |match|

                    next if !match
                    next if block && !block.call( match )

                    log(
                        :var => k,
                        :regexp  => regexp,
                        :match   => match,
                        :element => Issue::Element::HEADER
                    )
                }
            } if elems.include? Issue::Element::HEADER

        }
    end

    #
    # Logs a vulnerability based on a regular expression and it's matched string
    #
    # @param    [Regexp]    regexp
    # @param    [String]    match
    #
    def log( opts, res = nil )

        method = nil

        request_headers  = nil
        response_headers = @page.response_headers
        response         = @page.html
        url              = @page.url
        method           = @page.method.to_s.upcase if @page.method

        if( res )
            request_headers  = res.request.headers
            response_headers = res.headers
            response         = res.body
            url              = res.effective_url
            method           = res.request.method.to_s.upcase
        end

        if response_headers['content-type'] &&
           !response_headers['content-type'].substring?( 'text' )
            response = nil
        end

        begin
            print_ok( "In #{opts[:element]} var '#{opts[:altered]}' ( #{url} )" )
        rescue
        end

        print_verbose( "Injected string:\t" + opts[:injected] ) if opts[:injected]
        print_verbose( "Verified string:\t" + opts[:match].to_s ) if opts[:match]
        print_verbose( "Matched regular expression: " + opts[:regexp].to_s )
        print_debug( 'Request ID: ' + res.request.id.to_s ) if res
        print_verbose( '---------' ) if only_positives?

        # Instantiate a new Vulnerability class and
        # append it to the results array
        vuln = Issue.new( {
            :var          => opts[:altered],
            :url          => url,
            :injected     => opts[:injected],
            :id           => opts[:id],
            :regexp       => opts[:regexp],
            :regexp_match => opts[:match],
            :elem         => opts[:element],
            :verification => opts[:verification] || false,
            :method       => method,
            :response     => response,
            :opts         => opts,
            :headers      => {
                :request    => request_headers,
                :response   => response_headers,
            }
        }.merge( self.class.info ) )
        register_results( [vuln] )
    end

    #
    # Provides easy access to element auditing using simple injection and pattern
    # matching.
    #
    # If a block has been provided analysis and logging will be delegated to it,
    # otherwise, if a match is found it will be automatically logged.
    #
    # If no elements have been specified in 'opts' it will
    # use the elements from the module's "self.info()" hash. <br/>
    # If no elements have been specified in 'opts' or "self.info()" it will
    # use the elements in {OPTIONS}. <br/>
    #
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be used for custom analysis of responses; will be passed the following:
    #                                  * HTTP response
    #                                  * options
    #                                  * element
    #                                  The block will be called as soon as the
    #                                  HTTP response is received.
    #
    def audit( injection_str, opts = { }, &block )

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = self.class.info[:elements]
        end

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = OPTIONS[:elements]
        end

        opts  = OPTIONS.merge( opts )

        opts[:elements].each {
            |elem|

            case elem

                when  Element::LINK
                    audit_links( injection_str, opts, &block )

                when  Element::FORM
                    audit_forms( injection_str, opts, &block )

                when  Element::COOKIE
                    audit_cookies( injection_str, opts, &block )

                when  Element::HEADER
                    audit_headers( injection_str, opts, &block )
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )

            end

        }
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # This is called right before an [Arachni::Parser::Element]
    # is submitted/auditted and is used to determine whether to skip it or not.
    #
    # Implementation details are left up to the running module.
    #
    # @param    [Arachni::Parser::Element]  elem
    #
    def skip?( elem )
        return false
    end


    #
    # Audits elements using a 2 phase timing attack and logs results.
    #
    # 'opts' needs to contain a :timeout value in milliseconds.</br>
    # Optionally, you can add a :timeout_divider.
    #
    # Phase 1 uses the timeout value passed in opts, phase 2 uses (timeout * 2). </br>
    # If phase 1 fails, phase 2 is aborted. </br>
    # If we have a result in phase 1, phase 2 verifies that result with the higher timeout.
    #
    # @param   [Array]     strings     injection strings
    #                                       __TIME__ will be substituded with (timeout / timeout_divider)
    # @param  [Hash]        opts        options as described in {OPTIONS}
    #
    def audit_timeout( strings, opts )
        @@__timeout_audited     ||= Set.new
        @@__timeout_audit_queue ||= Queue.new

        delay = opts[:timeout]

        audit_timeout_debug_msg( 1, delay )
        timing_attack( strings, opts ) {
            |res, opts, elem|

            if !@@__timeout_audited.include?( __rdiff_audit_id( elem ) )
                elem.auditor( self )
                @@__timeout_audited << __rdiff_audit_id( elem )
                print_info( 'Found a candidate.' )
                @@__timeout_audit_queue << elem
            end
        }
    end

    def self.timeout_audit_queue
        @@__timeout_audit_queue ||= Queue.new
    end


    def self.audit_timeout_queue
        @@__timeout_audit_queue ||= Queue.new

        while( !@@__timeout_audit_queue.empty? )
            elem = @@__timeout_audit_queue.pop
            self.audit_timeout_phase_2( elem )
            elem.get_auditor.http.run
        end
    end

    #
    # Runs phase 2 of the timing attack auditng an individual element
    # (which passed phase 1) with a higher delay and timeout
    #
    def self.audit_timeout_phase_2( elem )

        opts = elem.opts
        opts[:timeout] *= 2
        # self.audit_timeout_debug_msg( 2, opts[:timeout] )

        str = opts[:timing_string].gsub( '__TIME__',
            ( opts[:timeout] / opts[:timeout_divider] ).to_s )

        # elem.auditor( self )

        elem.auditable = elem.orig
        c_opts = opts.merge( :format  => [ Format::APPEND ], :redundant => true,
            :timeout => (opts[:timeout] * 0.7).ceil )

        # this is the control; submit the element with an empty seed to make sure
        # that the web page is alive i.e won't time-out by default
        elem.audit( '', c_opts ) {
            |res|

            if !res.timed_out?

                elem.get_auditor.print_info( 'Liveness check was successful, progressing to verification...' )

                elem.audit( str, opts ) {
                    |res, opts|

                    if res.timed_out?

                        # all issues logged by timing attacks need manual verification.
                        # end of story.
                        opts[:verification] = true
                        elem.get_auditor.log( opts, res)
                    else
                        elem.get_auditor.print_info( 'Verification failed.' )
                    end
                }
            else
                elem.get_auditor.print_info( 'Liveness check failed, bailing out...' )
            end
        }

    end

    def audit_timeout_debug_msg( phase, delay )
        print_debug( '---------------------------------------------' )
        print_debug( "Running phase #{phase.to_s} of timing attack." )
        print_debug( "Delay set to: #{delay.to_s} milliseconds" )
        print_debug( '---------------------------------------------' )
    end

    #
    # Audits elements using a timing attack.
    #
    # 'opts' needs to contain a :timeout value in milliseconds.</br>
    # Optionally, you can add a :timeout_divider.
    #
    # @param   [Array]     strings     injection strings
    #                                       '__TIME__' will be substituded with (timeout / timeout_divider)
    # @param    [Hash]      opts        options as described in {OPTIONS}
    # @param    [Block]     &block      block to call if a timeout occurs,
    #                                       it will be passed the response and opts
    #
    def timing_attack( strings, opts, &block )

        opts[:timeout_divider] ||= 1
        [strings].flatten.each {
            |str|

            opts[:timing_string] = str
            str = str.gsub( '__TIME__', ( (opts[:timeout] + 3 * opts[:timeout_divider]) / opts[:timeout_divider] ).to_s )
            audit( str, opts ) {
                |res, opts, elem|
                block.call( res, opts, elem ) if block && res.timed_out?
            }
        }
    end

    #
    # Audits all elements types in opts[:elements] (or self.class.info[:elements]
    # if there are none in opts) using differential analysis attacks.
    #
    #    opts = {
    #        :precision => 3,
    #        :faults    => [ 'fault injections' ],
    #        :bools     => [ 'boolean injections' ]
    #    }
    #
    #    audit_rdiff( opts )
    #
    # Here's how it goes:
    #   let default be the default/original response
    #   let fault   be the response of the fault injection
    #   let bool    be the response of the boolean injection
    #
    #   a vulnerability is logged if default == bool AND bool.code == 200 AND fault != bool
    #
    # If a block has been provided analysis and logging will be delegated to it.
    #
    # @param    [Hash]      opts        available options:
    #                                   * :format -- as seen in {OPTIONS}
    #                                   * :elements -- as seen in {OPTIONS}
    #                                   * :train -- as seen in {OPTIONS}
    #                                   * :precision -- amount of rdiff iterations
    #                                   * :faults -- array of fault injection strings (these are supposed to force erroneous conditions when interpreted)
    #                                   * :bools -- array of boolean injection strings (these are supposed to not alter the webapp behavior when interpreted)
    # @param    [Block]     &block      block to be used for custom analysis of responses; will be passed the following:
    #                                   * injected string
    #                                   * audited element
    #                                   * default response body
    #                                   * boolean response
    #                                   * fault injection response body
    #
    def audit_rdiff( opts = {}, &block )

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = self.class.info[:elements]
        end

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = OPTIONS[:elements]
        end

        opts = {
            # append our seeds to the default values
            :format      => [ Format::APPEND ],
            # allow duplicate requests
            :redundant   => true,
            # amound of rdiff iterations
            :precision   => 2
        }.merge( opts )

        opts[:elements].each {
            |elem|

            case elem

                when  Element::LINK
                    next if !Options.instance.audit_links
                    @page.links.each {
                        |elem|
                        audit_rdiff_elem( elem, opts, &block )
                    }

                when  Element::FORM
                    next if !Options.instance.audit_forms
                    @page.forms.each {
                        |elem|
                        audit_rdiff_elem( elem, opts, &block )
                    }

                when  Element::COOKIE
                    next if !Options.instance.audit_cookies
                    @page.cookies.each {
                        |elem|
                        audit_rdiff_elem( elem, opts, &block )
                    }

                when  Element::HEADER
                    next if !Options.instance.audit_headers
                    @page.headers.each {
                        |elem|
                        audit_rdiff_elem( elem, opts, &block )
                    }
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )

            end

        }
    end

    #
    # Audits a single element using an rdiff attack.
    #
    # @param   [Arachni::Element::Auditable]     elem     the element to audit
    # @param    [Hash]      opts        same as for {#audit_rdiff}
    # @param    [Block]     &block      same as for {#audit_rdiff}
    #
    def audit_rdiff_elem( elem, opts = {}, &block )

        # don't continue if there's a missing value
        elem.auditable.values.each {
            |val|
            return if !val || val.empty?
        }

        return if __rdiff_audited?( elem )
        __rdiff_audited!( elem )

        responses = {
            :orig => nil,
            :good => {},
            :bad  => {},
            :bad_total  => 0,
            :good_total => 0
        }

        elem.auditor( self )
        opts[:precision].times {
            # get the default responses
            elem.audit( '', opts ) {
                |res|
                responses[:orig] ||= res.body
                # remove context-irrelevant dynamic content like banners and such
                # from the error page
                responses[:orig] = responses[:orig].rdiff( res.body )
            }
        }

        opts[:precision].times {
            opts[:faults].each {
                |str|

                # get injection variations that will hopefully cause an internal/silent
                # SQL error
                variations = elem.injection_sets( str, opts )

                responses[:bad_total] =  variations.size

                variations.each {
                    |c_elem|

                    print_status( c_elem.get_status_str( c_elem.altered ) )

                    # register us as the auditor
                    c_elem.auditor( self )
                    # submit the link and get the response
                    c_elem.submit( opts ).on_complete {
                        |res|

                        responses[:bad][c_elem.altered] ||= res.body.clone

                        # remove context-irrelevant dynamic content like banners and such
                        # from the error page
                        responses[:bad][c_elem.altered] =
                            responses[:bad][c_elem.altered].rdiff( res.body.clone )
                    }
                }
            }
        }

        opts[:bools].each {
            |str|

            # get injection variations that will not affect the outcome of the query
            variations = elem.injection_sets( str, opts )

            responses[:good_total] =  variations.size

            variations.each {
                |c_elem|

                print_status( c_elem.get_status_str( c_elem.altered ) )

                # register us as the auditor
                c_elem.auditor( self )
                # submit the link and get the response
                c_elem.submit( opts ).on_complete {
                    |res|

                    responses[:good][c_elem.altered] ||= []

                    # save the response for later analysis
                    responses[:good][c_elem.altered] << {
                        'str'  => str,
                        'res'  => res,
                        'elem' => c_elem
                    }
                }
            }
        }

        # when this runs the 'responses' hash will have been populated
        @http.after_run {

            responses[:good].keys.each {
                |key|

                responses[:good][key].each {
                    |res|

                    if block
                        block.call( res['str'], res['elem'], responses[:orig], res['res'], responses[:bad][key] )
                    elsif( responses[:orig] == res['res'].body &&
                        responses[:bad][key] != res['res'].body &&
                        !@http.custom_404?( res['res'] ) && res['res'].code == 200 )

                        url = res['res'].effective_url

                        # since we bypassed the auditor completely we need to create
                        # our own opts hash and pass it to the Vulnerability class.
                        #
                        # this is only required for Metasploitable vulnerabilities
                        opts = {
                            :injected_orig => res['str'],
                            :combo         => res['elem'].auditable
                        }

                        issue = Issue.new( {
                                :var          => key,
                                :url          => url,
                                :method       => res['res'].request.method.to_s,
                                :opts         => opts,
                                :injected     => res['str'],
                                :id           => res['str'],
                                :regexp       => 'n/a',
                                :regexp_match => 'n/a',
                                :elem         => res['elem'].type,
                                :response     => res['res'].body,
                                :verification => true,
                                :headers      => {
                                    :request    => res['res'].request.headers,
                                    :response   => res['res'].headers,
                                }
                            }.merge( self.class.info )
                        )

                        print_ok( "In #{res['elem'].type} var '#{key}' ( #{url} )" )

                        # register our results with the system
                        register_results( [ issue ] )
                    end

                }
            }
        }
    end

    def __rdiff_audited!( elem )
        @@__audited_rdiff ||= Set.new
        @@__audited_rdiff << __rdiff_audit_id( elem )
    end

    def __rdiff_audited?( elem )
        @@__audited_rdiff ||= Set.new
        @@__audited_rdiff.include?( __rdiff_audit_id( elem ) )
    end

    def __rdiff_audit_id( elem )
        elem.action + elem.auditable.keys.to_s
    end

    #
    # Provides the following methods:
    # * audit_links()
    # * audit_forms()
    # * audit_cookies()
    # * audit_headers()
    #
    # Metaprogrammed to avoid redundant code while maintaining compatibility
    # and method shortcuts.
    #
    # @see #audit_elems
    #
    def method_missing( sym, *args, &block )

        elem = sym.to_s.gsub!( 'audit_', '@' )
        raise NoMethodError.new( "Undefined method '#{sym.to_s}'.", sym, args ) if !elem

        elems = @page.instance_variable_get( elem )

        if( elems && elem )
            raise ArgumentError.new( "Missing required argument 'injection_str'" +
                " for audit_#{elem.gsub( '@', '' )}()." ) if( !args[0] )
            audit_elems( elems, args[0], args[1] ? args[1]: {}, &block )
        else
            raise NoMethodError.new( "Undefined method '#{sym.to_s}'.", sym, args )
        end
    end

    #
    # Audits Auditalble HTML/HTTP elements
    #
    # @param  [Array<Arachni::Element::Auditable>]  elements    elements to audit
    # @param  [String]  injection_str  same as for {#audit}
    # @param  [Hash]    opts           same as for {#audit}
    # @param  [Block]   &block         same as for {#audit}
    #
    # @see #method_missing
    #
    def audit_elems( elements, injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        url             = @page.url

        opts[:injected_orig] = injection_str

        elements.each{
            |elem|
            elem.auditor( self )
            elem.audit( injection_str, opts, &block )
        }
    end

end

end
end
