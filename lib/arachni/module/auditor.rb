=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
# Included by {Module::Base} and provides helper audit methods to all modules.
#
# There are 3 main types of audit and analysis techniques available:
#
# * {Arachni::Element::Capabilities::Auditable::Taint Taint analysis} -- {#audit}
# * {Arachni::Element::Capabilities::Auditable::Timeout Timeout analysis} -- {#audit_timeout}
# * {Arachni::Element::Capabilities::Auditable::RDiff Differential analysis} -- {#audit_rdiff}
#
# It should be noted that actual analysis takes place at the element level,
# and to be more specific, the {Arachni::Element::Capabilities::Auditable} element level.
#
# It also provides:
#
# * Discovery helpers for checking and logging the existence of remote files.
#   * {#log_remote_file}
#   * {#remote_file_exist?}
#   * {#log_remote_file_if_exists}
# * Pattern matching helpers for checking and logging the existence of strings
#   in responses or in the body of the page that's being audited.
#   * {#match_and_log}
# * General {Arachni::Issue} logging helpers.
#   * {#log}
#   * {#log_issue}
#   * {#register_results}
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Auditor
    include Output

    def self.reset
        audited.clear
        Element::Capabilities::Auditable::Timeout.reset
    end

    def self.timeout_audit_blocks
        Element::Capabilities::Auditable.timeout_audit_blocks
    end
    def self.timeout_candidates
        Element::Capabilities::Auditable.timeout_candidates
    end
    def self.timeout_loaded_modules
        Element::Capabilities::Auditable.timeout_loaded_modules
    end
    def self.on_timing_attacks( &block )
        Element::Capabilities::Auditable.on_timing_attacks( &block )
    end
    def self.running_timeout_attacks?
        Element::Capabilities::Auditable.running_timeout_attacks?
    end
    def self.timeout_audit_run
        Element::Capabilities::Auditable.timeout_audit_run
    end
    def self.timeout_audit_operations_cnt
        Element::Capabilities::Auditable.timeout_audit_operations_cnt
    end
    def self.current_timeout_audit_operations_cnt
        Element::Capabilities::Auditable.current_timeout_audit_operations_cnt
    end

    #
    # @param    [#to_s]  id  Identifier of the object to be marked as audited.
    #
    # @see #audited?
    #
    def audited( id )
        Auditor.audited << "#{self.class}-#{id}"
    end

    #
    # @param    [#to_s] id  Identifier of the object to be checked.
    #
    # @return   [Bool]  `true` if audited, `false` otherwise.
    #
    # @see #audited
    #
    def audited?( id )
        Auditor.audited.include?( "#{self.class}-#{id}" )
    end

    def self.included( m )
        m.class_eval do
            def self.issue_counter
                @issue_counter ||= 0
            end

            def self.issue_counter=( int )
                @issue_counter = int
            end

            def increment_issue_counter
                self.class.issue_counter += 1
            end

            def issue_limit_reached?( count = max_issues )
                self.class.issue_limit_reached?( count )
            end

            def self.issue_limit_reached?( count = max_issues )
                issue_counter >= count if !count.nil?
            end

            def self.max_issues
                info[:max_issues]
            end
        end
    end

    def max_issues
        self.class.max_issues
    end

    #
    # Holds constant bitfields that describe the preferred formatting
    # of injection strings.
    #
    Format = Element::Capabilities::Mutable::Format

    # Default audit options.
    OPTIONS = {
        #
        # Elements to audit.
        #
        # If no elements have been passed to audit methods, candidates will be
        # determined by {#candidate_elements}.
        #
        elements: [Element::LINK, Element::FORM,
                   Element::COOKIE, Element::HEADER,
                   Element::BODY],

        #
        # If set to `true` the HTTP response will be analyzed for new elements.
        # Be careful when enabling it, there'll be a performance penalty.
        #
        # If set to `false`, no training is going to occur.
        #
        # If set to `nil`, when the Auditor submits a form with original or
        # sample values this option will be overridden to `true`
        #
        train:    nil
    }

    #
    # *REQUIRED*
    #
    # @return   [Arachni::Page]  Page object you want to audit.
    # @abstract
    #
    attr_reader :page

    #
    # *REQUIRED*
    #
    # @return   [Arachni::Framework]
    #
    # @abstract
    #
    attr_reader :framework

    #
    # *OPTIONAL*
    #
    # Allows modules to ignore multi-Instance scope restrictions in order to
    # audit elements that are not on the sanctioned whitelist.
    #
    # @return   [Bool]
    #
    # @abstract
    #
    def override_instance_scope?
        false
    end

    # @return   [HTTP::Client]
    def http
        HTTP::Client
    end

    #
    # Just a delegator, logs an array of issues.
    #
    # @param    [Array<Arachni::Issue>]     issues
    #
    # @see Arachni::Module::Manager#register_results
    #
    def register_results( issues )
        return if issue_limit_reached?
        self.class.issue_counter += issues.size

        framework.modules.register_results( issues )
    end

    #
    # @note Ignores custom 404 responses.
    #
    # Logs a remote file or directory if it exists.
    #
    # @param    [String]    url Resource to check.
    # @param    [Bool]      silent
    #   If `false`, a message will be printed to stdout containing the status of
    #   the operation.
    # @param    [Proc]      block
    #   Called if the file exists, just before logging the issue, and is passed
    #   the HTTP response.
    #
    # @return   [Object]
    #   * `nil` if no URL was provided.
    #   * `false` if the request couldn't be fired.
    #   * `true` if everything went fine.
    #
    # @see #remote_file_exist?
    #
    def log_remote_file_if_exists( url, silent = false, &block )
        return nil if !url

        print_status( "Checking for #{url}" ) if !silent
        remote_file_exist?( url ) do |bool, res|
            print_status( 'Analyzing response for: ' + url ) if !silent
            next if !bool

            block.call( res ) if block_given?
            log_remote_file( res )

            # If the file exists let the trainer parse it since it may contain
            # brand new data to audit.
            framework.trainer.push( res )
        end
         true
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    #
    # @note Ignores custom 404 responses.
    #
    # Checks whether or not a remote resource exists.
    #
    # @param    [String]    url Resource to check.
    # @param    [Block] block
    #   Block to be passed  `true` if the resource exists, `false` otherwise.
    #
    # @return   [Object]
    #   * `nil` if no URL was provided.
    #   * `false` if the request couldn't be fired.
    #   * `true` if everything went fine.
    #
    def remote_file_exist?( url, &block )
        req  = http.get( url )
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
    alias :remote_file_exists? :remote_file_exist?

    #
    # Logs the existence of a remote file as an issue.
    #
    # @param    [HTTP::Response]    res
    # @param    [Bool]      silent
    #   If `false`, a message will be printed to stdout containing the status of
    #   the operation.
    #
    # @see #log_issue
    #
    def log_remote_file( res, silent = false )
        url = res.url
        filename = File.basename( res.parsed_url.path )

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

        print_ok( "Found #{filename} at #{url}" ) if !silent
    end
    alias :log_remote_directory :log_remote_file

    #
    # Helper method for issue logging.
    #
    # @param    [Hash]  opts    Issue options ({Issue}).
    #
    # @see Arachni::Module::Base#register_results
    #
    def log_issue( opts )
        # register the issue
        register_results( [ Issue.new( opts.merge( self.class.info ) ) ] )
    end

    #
    # Matches an array of regular expressions against a string and logs the
    # result as an issue.
    #
    # @param    [Array<Regexp>]     regexps
    #   Array of regular expressions to be tested.
    # @param    [String]            string
    #   String against which the `regexps` will be matched.
    #   (If no string has been provided the {#page} body will be used and, for
    #   good measure, `regexps` will also be matched against
    #   {Page#response_headers} as well.)
    # @param    [Block] block
    #   Block to verify matches before logging, must return `true`/`false`.
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
    # Populates and logs an {Arachni::Issue} based on data from `opts` and `res`.
    #
    # @param    [Hash]                  opts
    #   As passed to blocks by audit methods.
    # @param    [HTTP::Response]    res
    #   Optional HTTP response, defaults to page data.
    #
    def log( opts, res = nil )
        response_headers = {}
        request_headers  = {}
        response = nil
        method   = nil

        if page
            request_headers  = page.request_headers
            response_headers = page.response_headers
            response         = page.body
            url              = page.url
            method           = page.method.to_s.upcase if page.method
        end

        if res
            request_headers  = res.request.headers
            response_headers = res.headers
            response         = res.body
            url              = opts[:action] || res.url
            method           = res.request.method.to_s.upcase
        end

        if !response_headers['content-type'].to_s.include?( 'text' )
            response = nil
        end

        var     = opts[:altered] || opts[:var]
        element = opts[:element] || opts[:elem]

        msg = "In #{element}"
        msg << " var '#{var}'" if var
        print_ok "#{msg} ( #{url} )"

        print_verbose( "Injected string:\t" + opts[:injected] ) if opts[:injected]
        print_verbose( "Verified string:\t" + opts[:match].to_s ) if opts[:match]
        print_verbose( "Matched regular expression: " + opts[:regexp].to_s ) if opts[:regexp]
        print_debug( 'Request ID: ' + res.request.id.to_s ) if res
        print_verbose( '---------' ) if only_positives?

        # Platform identification by vulnerability.
        platform_type = nil
        if platform = opts[:platform]
            Platform::Manager[url] << platform if Options.fingerprint?
            platform_type = Platform::Manager[url].find_type( platform )
        end

        log_issue(
            var:           var,
            url:           url,
            platform:      platform,
            platform_type: platform_type,
            injected:      opts[:injected],
            id:            opts[:id],
            regexp:        opts[:regexp],
            regexp_match:  opts[:match],
            elem:          element,
            verification:  !!opts[:verification],
            remarks:       opts[:remarks],
            method:        method,
            response:      response,
            opts:          opts,
            headers:       {
                request:   request_headers,
                response:  response_headers,
            }
        )
    end

    # @see Arachni::Module::Base#preferred
    # @see Arachni::Module::Base.prefer
    # @abstract
    def preferred
        []
    end

    #
    # This is called right before an {Arachni::Element} is audited and is used
    # to determine whether to skip it or not.
    #
    # Running modules can override this as they wish *but* at their own peril.
    #
    # @param    [Arachni::Element]  elem
    #
    # @return   [Boolean]
    #   `true` if the element should be skipped, `false` otherwise.
    #
    def skip?( elem )
        # Find out our own shortname.
        @modname ||= framework.modules.map { |k, v| k if v == self.class }.compact.first

        # Don't audit elements which have been already logged as vulnerable
        # either by us or preferred modules.
        (preferred | [@modname]).each do |mod|
            next if !framework.modules.include?( mod )
            issue_id = elem.provisioned_issue_id( framework.modules[mod].info[:name] )
            return true if framework.modules.issue_set.include?( issue_id )
        end

        false
    end

    #
    # If no element types have been specified in `opts`, it will use the elements
    # from the module's {Base.info} hash.
    #
    # If no elements have been specified in `opts` or {Base.info}, it will use the
    # elements in {OPTIONS}.
    #
    # @param  [Hash]    opts
    # @option opts  [Array]  :elements
    #   Element types to audit (see {OPTIONS}`[:elements]`).
    #
    # @return   [Array<Arachni::Element>]   Prepared elements.
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
            next if !Options.audit?( elem )

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
                    fail ArgumentError, "Unknown element: #{elem}"
            end
        end

        elements.map { |e| d = e.dup; d.auditor = self; d }
    end

    #
    # If a block has been provided it calls {Arachni::Element::Capabilities::Auditable#audit}
    # for every element, otherwise, it defaults to {#audit_taint}.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable#audit
    # @see #audit_taint
    #
    def audit( payloads, opts = {}, &block )
        opts = OPTIONS.merge( opts )
        if !block_given?
            audit_taint( payloads, opts )
        else
            candidate_elements( opts ).each { |e| e.audit( payloads, opts, &block ) }
        end
    end

    #
    # Provides easy access to element auditing using simple taint analysis
    # and automatically logs results.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable::Taint
    #
    def audit_taint( payloads, opts = {} )
        opts = OPTIONS.merge( opts )
        candidate_elements( opts ).each { |e| e.taint_analysis( payloads, opts ) }
    end

    #
    # Audits elements using differential analysis and automatically logs results.
    #
    # Uses {#candidate_elements} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable::RDiff
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
    # @see Arachni::Element::Capabilities::Auditable::Timeout
    #
    def audit_timeout( payloads, opts = {} )
        opts = OPTIONS.merge( opts )
        candidate_elements( opts ).each { |e| e.timeout_analysis( payloads, opts ) }
    end

    private

    #
    # Helper `Set` for modules which want to keep track of what they've audited
    # by themselves.
    #
    # @return   [Set]
    #
    # @see #audited?
    # @see #audited
    #
    def self.audited
        @audited ||= Support::LookUp::HashSet.new
    end

end

end
end
