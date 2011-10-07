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
# @version: 0.3.1
#
module Auditor

    def self.included( mod )
        # @@__timeout_audited      ||= Set.new

        # holds timing-attack performing Procs to be run after all
        # non-tming-attack modules have finished.
        @@__timeout_audit_blocks   ||= Queue.new

        # populated by timing attack phase 1 with
        # candidate elements to be verified by phase 2
        @@__timeout_candidates     ||= Queue.new

        # modules which have called the timing attack audit mthod (audit_timeout)
        # we're interested in the amount, not the names, and is used to
        # determine scan progress
        @@__timeout_loaded_modules ||= Set.new

        # the rdiff attack performs it own redundancy checks so we need this to
        # keep track audited elements
        @@__rdiff_audited ||= Set.new
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
    # Logs a remote file if it exists
    #
    # @param    [String]    url
    # @param    [Proc]      &block  called if the file exists, just before logging
    #
    def log_remote_file_if_exists( url, &block )
        req  = @http.get( url, :train => true )
        req.on_complete {
            |res|

            if remote_file_exist?( res )
                block.call( res ) if block_given?
                log_remote_file( res )
            end
        }
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    #
    # Checks that the response points to an existing file/page and not
    # an error or custom 404 response
    #
    # @param    [Typhoeus::Response]    res
    #
    def remote_file_exist?( res )
        res.code == 200 && !@http.custom_404?( res )
    end

    #
    # Logs the existence of a remote file.
    #
    # @param    [Typhoeus::Response]    res
    #
    def log_remote_file( res )
        url = res.effective_url
        filename = File.basename( URI( res.effective_url ).path )

        log_issue(
            :url          => url,
            :injected     => filename,
            :id           => filename,
            :elem         => Issue::Element::PATH,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

    end
    alias :log_remote_directory :log_remote_file

    #
    # Helper method for issue logging.
    #
    # @param    [Hash]  opts    issue options ({Issue})
    # @param    [Bool]  include_class_info    merge opts with module.info?
    #
    def log_issue( opts )
        # register the issue
        register_results( [ Issue.new( opts.merge( self.class.info ) ) ] )
    end

    #
    # Matches the "string" (default string is the HTML code in @page.html) to
    # an array of regular expressions and logs the results.
    #
    # For good measure, regexps will also be run against the page headers (@page.response_headers).
    #
    # @param    [Array<Regexp>]     regexps     array of regular expressions to be tested
    # @param    [String]            string      string to
    # @param    [Block]             block       block to verify matches before logging,
    #                                           must return true/false
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
    # Populates and logs an {Arachni::Issue} based on data from "opts" and "res".
    #
    # @param    [Hash]                  opts    as passed to blocks by audit methods
    # @param    [Typhoeus::Response]    res     defaults to @page data
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
            url              = opts[:action]
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

        # Instantiate a new Issue class and append it to the results array
        log_issue(
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
        )
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
    # This is called right before an [Arachni::Parser::Element]
    # is submitted/auditted and is used to determine whether to skip it or not.
    #
    # Running modules can override this as they wish *but* at their own peril.
    #
    # @param    [Arachni::Parser::Element]  elem
    #
    def skip?( elem )
        redundant.map {
            |mod|

            mod_name = @framework.modules[mod].info[:name]

            set_id = @framework.modules.class.issue_set_id_from_elem( mod_name, elem )
            return true if @framework.modules.issue_set.include?( set_id )
        }

        return false
    end


    #
    # Audits elements using timing attacks and automatically logs results.
    #
    # Here's how it works:
    # * Loop 1 -- Populates the candidate queue. We're picking the low hanging
    #   fruit here so we can run this in larger concurrent bursts which cause *lots* of noise.
    #   - Initial probing for candidates -- Any element that times out is added to a queue.
    #   - Stabilization -- The candidate is submited with its default values in
    #     order to wait until the effects of the timing attack have worn off.
    # * Loop 2 -- Verifies the candidates. This is much more delicate so the
    #   concurrent requests are lowered to pairs.
    #   - Liveness test -- Ensures that stabilization was successful before moving on.
    #   - Verification using an increased timeout -- Any elements that time out again are logged.
    #   - Stabilization
    #
    # Ideally, all requests involved with timing attacks would be run in sync mode
    # but the performance penalties are too high, thus we compromise and make the best of it
    # by running as little an amount of concurrent requests as possible for any given phase.
    #
    #    opts = {
    #        :format  => [ Format::STRAIGHT ],
    #        :timeout => 4000,
    #        :timeout_divider => 1000
    #    }
    #
    #    audit_timeout( [ 'sleep( __TIME__ );' ], opts )
    #
    #
    # @param   [Array]     strings     injection strings
    #                                       __TIME__ will be substituded with (timeout / timeout_divider)
    # @param  [Hash]        opts        options as described in {OPTIONS} with the following extra:
    #                                   * :timeout -- milliseconds to wait for the request to complete
    #                                   * :timeout_divider -- __TIME__ = timeout / timeout_divider
    #
    def audit_timeout( strings, opts )
        @@__timeout_loaded_modules << self.class.info[:name]

        @@__timeout_audit_blocks << Proc.new {
            delay = opts[:timeout]

            audit_timeout_debug_msg( 1, delay )
            timing_attack( strings, opts ) {
                |res, c_opts, elem|

                elem.auditor( self )

                print_info( "Found a candidate -- #{elem.type.capitalize} input '#{elem.altered}' at #{elem.action}" )

                Arachni::Module::Auditor.audit_timeout_stabilize( elem )

                @@__timeout_candidates << elem
            }
        }
    end

    #
    # Returns the names of all loaded modules that use timing attacks.
    #
    # @return   [Set]
    #
    def self.timeout_loaded_modules
        @@__timeout_loaded_modules
    end

    #
    # Holds timing-attack performing Procs to be run after all
    # non-tming-attack modules have finished.
    #
    # @return   [Queue]
    #
    def self.timeout_audit_blocks
        @@__timeout_audit_blocks
    end

    #
    # Runs all blocks in {timeout_audit_blocks} and verifies
    # and logs the candidate elements.
    #
    def self.timeout_audit_run
        while( !@@__timeout_audit_blocks.empty? )
            @@__timeout_audit_blocks.pop.call
        end

        while( !@@__timeout_candidates.empty? )
            self.audit_timeout_phase_2( @@__timeout_candidates.pop )
        end
    end

    #
    # Runs phase 2 of the timing attack auditng an individual element
    # (which passed phase 1) with a higher delay and timeout
    #
    def self.audit_timeout_phase_2( elem )

        # reset the audited list since we're going to re-audit the elements
        # @@__timeout_audited = Set.new

        opts = elem.opts
        opts[:timeout] *= 2
        # opts[:async]    = false
        # self.audit_timeout_debug_msg( 2, opts[:timeout] )

        str = opts[:timing_string].gsub( '__TIME__',
            ( opts[:timeout] / opts[:timeout_divider] ).to_s )

        opts[:timeout] *= 0.7

        elem.auditable = elem.orig

        # this is the control; request the URL of the element to make sure
        # that the web page is alive i.e won't time-out by default
        elem.get_auditor.http.get( elem.action ).on_complete {
            |res|

            if !res.timed_out?

                elem.get_auditor.print_info( 'Liveness check was successful, progressing to verification...' )

                elem.audit( str, opts ) {
                    |c_res, c_opts|

                    if c_res.timed_out?

                        # all issues logged by timing attacks need manual verification.
                        # end of story.
                        c_opts[:verification] = true
                        elem.get_auditor.log( c_opts, c_res )

                        self.audit_timeout_stabilize( elem )

                    else
                        elem.get_auditor.print_info( 'Verification failed.' )
                    end
                }
            else
                elem.get_auditor.print_info( 'Liveness check failed, bailing out...' )
            end
        }

        elem.get_auditor.http.run
    end

    #
    # Submits an element which has just been audited using a timing attack
    # with a high timeout in order to determine when the effects of a timing
    # attack has worn off in order to safely continue the audit.
    #
    # @param    [Arachni::Element::Auditable]   elem
    #
    def self.audit_timeout_stabilize( elem )

        d_opts = {
            :skip_orig => true,
            :redundant => true,
            :timeout   => 120000,
            :silent    => true,
            :async     => false
        }

        orig_opts = elem.opts

        elem.get_auditor.print_info( 'Waiting for the effects of the timing attack to wear off.' )
        elem.get_auditor.print_info( 'Max waiting time: ' + ( d_opts[:timeout] /1000 ).to_s + ' seconds.' )

        elem.auditable = elem.orig
        res = elem.submit( d_opts ).response

        if !res.timed_out?
            elem.get_auditor.print_info( 'Server seems responsive again.' )
        else
            elem.get_auditor.print_error( 'Max waiting time exceeded, the server may be dead.' )
        end

        elem.opts.merge!( orig_opts )
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
        # opts[:async] = false

        [strings].flatten.each {
            |str|

            opts[:timing_string] = str
            str = str.gsub( '__TIME__', ( (opts[:timeout] + 3 * opts[:timeout_divider]) / opts[:timeout_divider] ).to_s )
            opts[:skip_orig] = true

            audit( str, opts ) {
                |res, c_opts, elem|
                block.call( res, c_opts, elem ) if block && res.timed_out?
            }
        }

        @http.run
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
    # The "bool" response is also checked in order to determine if it's a custom 404, if it is it'll be skipped.
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
                        |c_elem|
                        audit_rdiff_elem( c_elem, opts, &block )
                    }

                when  Element::FORM
                    next if !Options.instance.audit_forms
                    @page.forms.each {
                        |c_elem|
                        audit_rdiff_elem( c_elem, opts, &block )
                    }

                when  Element::COOKIE
                    next if !Options.instance.audit_cookies
                    @page.cookies.each {
                        |c_elem|
                        audit_rdiff_elem( c_elem, opts, &block )
                    }

                when  Element::HEADER
                    next if !Options.instance.audit_headers
                    @page.headers.each {
                        |c_elem|
                        audit_rdiff_elem( c_elem, opts, &block )
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
        @@__rdiff_audited << __rdiff_audit_id( elem )
    end

    def __rdiff_audited?( elem )
        @@__rdiff_audited.include?( __rdiff_audit_id( elem ) )
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
