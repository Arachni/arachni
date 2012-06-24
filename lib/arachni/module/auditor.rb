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
# Included by {Module::Base} and provides helper audit methods to all modules.
#
# There are 3 main types of audit and analysis techniques available:
# * Taint analysis -- {#audit}
# * Timeout analysis -- {#audit_timeout}
# * Differential analysis -- {#audit_rdiff}
#
# It should be noted that actual analysis takes place at the element level,
# and to be more specific, the {Arachni::Parser::Element::Auditable} element level.
#
# The module also provides:
# * discovery helpers for checking and logging the existence of remote files
# * pattern matching helpers for checking and logging the existence of strings
#   in responses or in the body of the page that's being audited
# * general {Arachni::Issue} logging helpers
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Auditor
    include Arachni::Module::Output

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
    # Holds constants that describe Issue severities.
    #
    module Severity
        include Arachni::Issue::Severity
    end

    OPTIONS = {
        #
        # Elements to audit.
        #
        # If no elements have been passed to audit candidates will be
        # determined by {#candidate_elements}.
        #
        elements: [Element::LINK, Element::FORM,
                   Element::COOKIE, Element::HEADER,
                   Element::BODY],

        #
        # If 'train' is set to true the HTTP response will be
        # analyzed for new elements. <br/>
        # Be careful when enabling it, there'll be a performance penalty.
        #
        # When the Auditor submits a form with original or sample values
        # this option will be overridden to true.
        #
        train:    false,
    }

    #
    # REQUIRED
    #
    # Must return the Page object you wish to be audited.
    #
    # @return   [Arachni::Parser::Page]
    # @abstract
    #
    attr_reader :page

    #
    # REQUIRED
    #
    # Must return the Framework
    #
    # @return   [Arachni::Framework]
    #
    # @abstract
    #
    def framework
    end

    #
    # OPTIONAL
    #
    # Prevents auditing elements that have been previously
    # logged by any of the modules returned by this method.
    #
    # @return   [Array]     module names
    #
    # @abstract
    #
    def redundant
        # [ 'sqli', 'sqli_blind_rdiff' ]
        []
    end

    #
    # OPTIONAL
    #
    # Allows modules to ignore HPG scope restrictions
    #
    # This way they can audit elements that are not on the Grid sanctioned whitelist.
    #
    # @return   [Bool]
    #
    # @abstract
    #
    def override_instance_scope?
        false
    end

    # @return   [Arachni::HTTP]
    def http
        Arachni::HTTP.instance
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
    # @param    [Proc]      block  called if the file exists, just before logging
    #
    # @return   [Object]    - nil if no URL was provided
    #                       - false if the request couldn't be fired
    #                       - true if everything went fine
    #
    # @see #remote_file_exist?
    #
    def log_remote_file_if_exists( url, silent = false, &block )
        return nil if !url

        remote_file_exist?( url ) do |bool, res|
            print_status( 'Analyzing response for: ' + url ) if !silent

            if bool
                block.call( res ) if block_given?
                log_remote_file( res )

                # if the file exists let the trainer parse it since it may
                # contain brand new data to audit
                http.trainer.add_response( res )
            end
        end
         true
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    #
    # Checks that the response points to an existing file/page and not
    # an error or custom 404 response.
    #
    # @param    [String]    url
    #
    def remote_file_exist?( url, &block )
        req  = http.get( url, remove_id: true )
        return false if !req

        req.on_complete do |res|
            if res.code != 200
                block.call( false, res )
            else
                http.custom_404?( res ) { |bool| block.call( !bool, res ) }
            end
        end
        true
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
            url:      url,
            injected: filename,
            id:       filename,
            elem:     Element::PATH,
            response: res.body,
            headers:  {
                request:  res.request.headers,
                response: res.headers,
            }
        )
    end
    alias :log_remote_directory :log_remote_file

    #
    # Helper method for issue logging.
    #
    # @param    [Hash]  opts    issue options ({Issue})
    #
    # @see Arachni::Module::Base#register_results
    #
    def log_issue( opts )
        # register the issue
        register_results( [ Arachni::Issue.new( opts.merge( self.class.info ) ) ] )
    end

    #
    # Matches the "string" (default string is the HTML code in page.body) to
    # an array of regular expressions and logs the results.
    #
    # For good measure, regexps will also be run against the page headers (page.response_headers).
    #
    # @param    [Array<Regexp>]     regexps     array of regular expressions to be tested
    # @param    [String]            string      string to
    # @param    [Block]             block       block to verify matches before logging,
    #                                           must return true/false
    #
    def match_and_log( regexps, string = page.body, &block )
        # make sure that we're working with an array
        regexps = [regexps].flatten

        elems = self.class.info[:elements]
        elems = OPTIONS[:elements] if !elems || elems.empty?

        regexps.each do |regexp|
            string.scan( regexp ).flatten.uniq.each do |match|

                next if !match
                next if block && !block.call( match )

                log(
                    regexp:  regexp,
                    match:   match,
                    element: Element::BODY
                )
            end if elems.include? Element::BODY

            next if string != page.body

            page.response_headers.each do |k,v|
                next if !v

                v.to_s.scan( regexp ).flatten.uniq.each do |match|
                    next if !match
                    next if block && !block.call( match )

                    log(
                        var:     k,
                        regexp:  regexp,
                        match:   match,
                        element: Element::HEADER
                    )
                end
            end if elems.include? Element::HEADER

        end
    end

    #
    # Populates and logs an {Arachni::Issue} based on data from "opts" and "res".
    #
    # @param    [Hash]                  opts    as passed to blocks by audit methods
    # @param    [Typhoeus::Response]    res     defaults to page data
    #
    def log( opts, res = nil )
        response_headers = {}
        request_headers  = {}
        response = nil
        method   = nil

        if page
            request_headers  = nil
            response_headers = page.response_headers
            response         = page.body
            url              = page.url
            method           = page.method.to_s.upcase if page.method
        end

        if res
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
        print_verbose( "Matched regular expression: " + opts[:regexp].to_s ) if opts[:regexp]
        print_debug( 'Request ID: ' + res.request.id.to_s ) if res
        print_verbose( '---------' ) if only_positives?

        log_issue(
            var:          opts[:altered],
            url:          url,
            injected:     opts[:injected],
            id:           opts[:id],
            regexp:       opts[:regexp],
            regexp_match: opts[:match],
            elem:         opts[:element],
            verification: !!opts[:verification],
            method:       method,
            response:     response,
            opts:         opts,
            headers:      {
                request:  request_headers,
                response: response_headers,
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
        redundant.map do |mod|
            next if !framework.modules.include?( mod )
            mod_name = framework.modules[mod].info[:name]

            set_id = framework.modules.issue_set_id_from_elem( mod_name, elem )
            return true if framework.modules.issue_set.include?( set_id )
        end if framework

        false
    end

    #
    # Returns a list of prepared elements to be audited.
    #
    # If no element types have been specified in 'opts' it will
    # use the elements from the module's "self.info()" hash.
    #
    # If no elements have been specified in 'opts' or "self.info()" it will
    # use the elements in {OPTIONS}.
    #
    # @param  [Hash]    opts  options as described in {OPTIONS} -- only interested in opts[:elements]
    #
    # @return   [Array<Arachni::Parser::Element::Auditable]   array of auditable elements
    #
    def candidate_elements( opts = {} )
        if !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty?
            opts[:elements] = self.class.info[:elements]
        end

        if !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty?
            opts[:elements] = OPTIONS[:elements]
        end

        elements = []
        opts[:elements].each do |elem|
            next if !Arachni::Options.instance.instance_variable_get( "@audit_#{elem}s".to_sym )

            elements |= case elem
                when Element::LINK
                    page.links

                when Element::FORM
                    page.forms

                when Element::COOKIE
                    page.cookies

                when Element::HEADER
                    page.headers

                when Element::BODY
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )
            end
        end

        elements.map { |e| e.auditor = self; e }
    end

    #
    # If a block has been provided it calls {Arachni::Parser::Element::Auditable#audit}
    # for every element, otherwise, it defaults to {#audit_taint}.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Parser::Element::Auditable#audit
    # @see #audit_taint
    #
    def audit( injection_str, opts = {}, &block )
        opts = OPTIONS.merge( opts )
        if !block_given?
            audit_taint( injection_str, opts )
        else
            candidate_elements( opts ).each { |e| e.audit( injection_str, opts, &block ) }
        end
    end

    #
    # Provides easy access to element auditing using simple taint analysis.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Parser::Element::Analysis::Taint
    #
    def audit_taint( taint, opts = {} )
        opts = OPTIONS.merge( opts )
        candidate_elements( opts ).each { |e| e.taint_analysis( taint, opts ) }
    end

    #
    # Audits elements using differential analysis attacks.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Parser::Element::Analysis::RDiff
    #
    def audit_rdiff( opts = {}, &block )
        opts = OPTIONS.merge( opts )
        candidate_elements( opts ).each { |e| e.rdiff_analysis( opts, &block ) }
    end

    #
    # Audits elements using timing attacks and automatically logs results.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Parser::Element::Analysis::Timeout
    #
    def audit_timeout( strings, opts = {} )
        opts = OPTIONS.merge( opts )
        candidate_elements( opts ).each { |e| e.timeout_analysis( strings, opts ) }
    end

end

end
end
