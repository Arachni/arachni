=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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

    def self.timeout_audit_blocks
        Arachni::Parser::Element::Auditable.timeout_audit_blocks
    end
    def self.timeout_loaded_modules
        Arachni::Parser::Element::Auditable.timeout_loaded_modules
    end
    def self.on_timing_attacks( &block )
        Arachni::Parser::Element::Auditable.on_timing_attacks( &block )
    end
    def self.running_timeout_attacks?
        Arachni::Parser::Element::Auditable.running_timeout_attacks?
    end
    def self.timeout_audit_run
        Arachni::Parser::Element::Auditable.timeout_audit_run
    end
    def self.timeout_audit_operations_cnt
        Arachni::Parser::Element::Auditable.timeout_audit_operations_cnt
    end
    def self.current_timeout_audit_operations_cnt
        Arachni::Parser::Element::Auditable.current_timeout_audit_operations_cnt
    end

    #
    # Holds constant bitfields that describe the preferred formatting
    # of injection strings.
    #
    module Format
        include Arachni::Parser::Element::Mutable::Format
    end

    #
    # Holds constants that describe the HTML elements to be audited.
    #
    module Element
        include Arachni::Issue::Element
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
        # Be careful when enabling it, there'll be a performance penalty.
        #
        # When the Auditor submits a form with original or sample values
        # this option will be overridden to true.
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
    # ABSTRACT - REQUIRED
    #
    # Must return an HTTP instance
    #
    # @return   [Arachni::HTTP]
    #
    def http
    end

    #
    # ABSTRACT - REQUIRED
    #
    # Must return the Page object you wish to be audited
    #
    # @return   [Arachni::Parser::Page]
    #
    def page
    end

    #
    # ABSTRACT - REQUIRED
    #
    # Must return the Framework
    #
    # @return   [Arachni::Framework]
    #
    def framework
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # Prevents auditing elements that have been previously
    # logged by any of the modules returned by this method.
    #
    # @return   [Array]     module names
    #
    def redundant
        # [ 'sqli', 'sqli_blind_rdiff' ]
        []
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # Allows modules to ignore HPG scope restrictions
    #
    # This way they can audit elements that are not on the Grid sanctioned whitelist.
    #
    # @return   [Bool]
    #
    def override_instance_scope?
        false
    end

    #
    # Just a delegator logs an array of issues.
    #
    # @param    [Array<Arachni::Issue>]     issues
    #
    # @see Arachni::Module::Manager.register_results
    #
    def register_results( issues )
        Arachni::Module::Manager.register_results( issues )
    end

    #
    # Logs a remote file or directory if it exists.
    #
    # @param    [String]    url
    # @param    [Bool]      silent  if false, a message will be sent to stdout
    #                               containing the status of the operation.
    # @param    [Proc]      &block  called if the file exists, just before logging
    #
    # @return   [Object]    - nil if no URL was provided
    #                       - false if the request couldn't be fired
    #                       - true if everything went fine
    #
    # @see #remote_file_exist?
    #
    def log_remote_file_if_exists( url, silent = false, &block )
        return nil if !url

        remote_file_exist?( url ) {
            |bool, res|

            print_status( 'Analyzing response for: ' + url ) if !silent

            if bool
                block.call( res ) if block_given?
                log_remote_file( res )

                # if the file exists let the trainer parse it since it may
                # contain brand new data to audit
                http.trainer.add_response( res )
            end
        }

        return true
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    #
    # Checks that the response points to an existing file/page and not
    # an error or custom 404 response.
    #
    # @param    [Typhoeus::Response]    res
    #
    def remote_file_exist?( url, &block )
        req  = http.get( url, :remove_id => true )
        return false if !req

        req.on_complete {
            |res|
            if res.code != 200
                block.call( false, res )
            else
                http.custom_404?( res ) {
                    |bool|
                    block.call( !bool, res )
                }
            end
        }
        return true
    end

    #
    # Logs the existence of a remote file as an issue.
    #
    # @param    [Typhoeus::Response]    res
    #
    # @see #log_issue
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
    # @see Arachni::Module::Base#register_results
    #
    def log_issue( opts )
        # register the issue
        register_results( [ Issue.new( opts.merge( self.class.info ) ) ] )
    end

    #
    # Matches the "string" (default string is the HTML code in page.html) to
    # an array of regular expressions and logs the results.
    #
    # For good measure, regexps will also be run against the page headers (page.response_headers).
    #
    # @param    [Array<Regexp>]     regexps     array of regular expressions to be tested
    # @param    [String]            string      string to
    # @param    [Block]             block       block to verify matches before logging,
    #                                           must return true/false
    #
    def match_and_log( regexps, string = page.html, &block )

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

            next if string == page.html

            page.response_headers.each {
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
    # @param    [Typhoeus::Response]    res     defaults to page data
    #
    def log( opts, res = nil )

        method = nil

        if( page )
            request_headers  = nil
            response_headers = page.response_headers
            response         = page.html
            url              = page.url
            method           = page.method.to_s.upcase if page.method
        end

        if( res )
            request_headers  = res.request.headers
            response_headers = res.headers
            response         = res.body
            url              = opts[:action] || res.effective_url
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
    # This is called right before an [Arachni::Parser::Element]
    # is submitted/audited and is used to determine whether to skip it or not.
    #
    # Running modules can override this as they wish *but* at their own peril.
    #
    # @param    [Arachni::Parser::Element]  elem
    #
    def skip?( elem )
        redundant.map {
            |mod|

            mod_name = framework.modules[mod].info[:name]

            set_id = framework.modules.class.issue_set_id_from_elem( mod_name, elem )
            return true if framework.modules.issue_set.include?( set_id )
        } if framework

        return false
    end

    def candidate_elements( opts = {} )
        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = self.class.info[:elements]
        end

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = OPTIONS[:elements]
        end

        elements = []
        opts[:elements].each {
            |elem|
            next if !Arachni::Options.instance.instance_variable_get( "@audit_#{elem}s".to_sym )

            case elem
                when Element::LINK
                    elements |= page.links

                when Element::FORM
                    elements |= page.forms

                when Element::COOKIE
                    elements |= page.cookies

                when Element::HEADER
                    elements |= page.headers

                when Element::BODY
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )
            end
        }

        elements
    end

    #
    # Provides easy access to element auditing using simple taint analysis.
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
        candidate_elements( opts ).each {
            |element|
            element.auditor = self
            if block_given?
                element.audit( injection_str, opts, &block )
            else
                element.taint_analysis( injection_str, opts )
            end
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
        candidate_elements( opts ).each {
            |element|
            element.auditor = self
            element.rdiff_analysis( opts, &block )
        }
    end

    #
    # Audits elements using timing attacks and automatically logs results.
    #
    # Here's how it works:
    # * Loop 1 -- Populates the candidate queue. We're picking the low hanging
    #   fruit here so we can run this in larger concurrent bursts which cause *lots* of noise.
    #   - Initial probing for candidates -- Any element that times out is added to a queue.
    #   - Stabilization -- The candidate is submitted with its default values in
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
    #                                       __TIME__ will be substituted with (timeout / timeout_divider)
    # @param  [Hash]        opts        options as described in {OPTIONS} with the following extra:
    #                                   * :timeout -- milliseconds to wait for the request to complete
    #                                   * :timeout_divider -- __TIME__ = timeout / timeout_divider
    #
    def audit_timeout( strings, opts = {} )
        candidate_elements( opts ).each {
            |element|
            element.auditor = self
            element.timeout_analysis( strings, opts )
        }
    end

end

end
end
