=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Check

# Included by {Check::Base} and provides helper audit methods to all checks.
#
# There are 3 main types of audit and analysis techniques available:
#
# * {Arachni::Element::Capabilities::Auditable::Taint Taint analysis} -- {#audit}
# * {Arachni::Element::Capabilities::Auditable::Timeout Timeout analysis} -- {#audit_timeout}
# * {Arachni::Element::Capabilities::Auditable::Differential Differential analysis} -- {#audit_differential}
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
module Auditor
    def self.reset
        audited.clear
    end

    def self.has_timeout_candidates?
        Element::Capabilities::Auditable::Timeout.has_candidates?
    end
    def self.timeout_audit_run
        Element::Capabilities::Auditable::Timeout.run
    end

    # @param    [#to_s]  id  Identifier of the object to be marked as audited.
    #
    # @see #audited?
    def audited( id )
        Auditor.audited << "#{self.class}-#{id}"
    end

    # @param    [#to_s] id  Identifier of the object to be checked.
    #
    # @return   [Bool]  `true` if audited, `false` otherwise.
    #
    # @see #audited
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

            # Helper method for creating an issue.
            #
            # @param    [Hash]  options {Issue} options.
            def self.create_issue( options )
                check_info = self.info.dup
                check_info.delete( :issue )
                check_info[:shortname] = self.shortname

                issue_data = self.info[:issue].merge( check: check_info ).merge( options )
                Issue.new( issue_data )
            end
        end
    end

    def max_issues
        self.class.max_issues
    end

    # Holds constant bitfields that describe the preferred formatting
    # of injection strings.
    Format = Element::Capabilities::Mutable::Format

    # Default audit options.
    OPTIONS = {
        # Elements to audit.
        #
        # If no elements have been passed to audit methods, candidates will be
        # determined by {#each_candidate_element}.
        elements: [Element::Link, Element::Form,
                   Element::Cookie, Element::Header,
                   Element::Body],

        # If set to `true` the HTTP response will be analyzed for new elements.
        # Be careful when enabling it, there'll be a performance penalty.
        #
        # If set to `false`, no training is going to occur.
        #
        # If set to `nil`, when the Auditor submits a form with original or
        # sample values this option will be overridden to `true`
        train:    nil
    }

    # *REQUIRED*
    #
    # @return   [Arachni::Page]  Page object you want to audit.
    # @abstract
    attr_reader :page

    # *REQUIRED*
    #
    # @return   [Arachni::Framework]
    # @abstract
    attr_reader :framework

    # *OPTIONAL*
    #
    # Allows checks to ignore multi-Instance scope restrictions in order to
    # audit elements that are not on the sanctioned whitelist.
    #
    # @return   [Bool]
    # @abstract
    def override_instance_scope?
        false
    end

    # @return   [HTTP::Client]
    def http
        HTTP::Client
    end

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
    # @see Element::Server#log_remote_file_if_exists?
    # @see Element::Server#remote_file_exist?
    def log_remote_file_if_exists( url, silent = false, &block )
        Element::Server.new( page.response ).tap { |s| s.auditor = self }.
            log_remote_file_if_exists( url, silent, &block )
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    # Matches an array of regular expressions against a string and logs the
    # result as an issue.
    #
    # @param    [Array<Regexp>]     patterns
    #   Array of regular expressions to be tested.
    # @param    [Block] block
    #   Block to verify matches before logging, must return `true`/`false`.
    #
    # @see Element::Body#match_and_log
    def match_and_log( patterns, &block )
        Element::Body.new( page ).tap { |b| b.auditor = self }.
            match_and_log( patterns, &block )
    end

    # Populates and logs an {Arachni::Issue}.
    #
    # @param    [Hash]  options
    #   As passed to blocks by audit methods.
    # @param    [HTTP::Response]    response
    #   Optional HTTP response, defaults to page data.
    def log( options, response = page.response )
        vector        = options[:vector]
        audit_options = vector.respond_to?( :audit_options ) ?
            vector.audit_options : {}

        msg = "In #{vector.type}"

        active = vector.respond_to?( :affected_input_name ) && vector.affected_input_name

        if active
            msg << " input '#{vector.affected_input_name}'"
        end

        print_ok "#{msg} ( #{vector.action} )"

        print_verbose( "Injected:\t#{vector.affected_input_value}" ) if active
        print_verbose( "Signature:\t#{options[:signature]}" ) if options[:signature]
        print_verbose( "Proof:\t#{options[:proof]}" )         if options[:proof]
        print_debug( "Request ID:\t#{response.request.id}" )
        print_verbose( '---------' )                          if only_positives?

        # Platform identification by vulnerability.
        platform_type = nil
        if (platform = (options.delete(:platform) || audit_options[:platform]))
            Platform::Manager[vector.action] << platform if Options.fingerprint?
            platform_type = Platform::Manager[vector.action].find_type( platform )
        end

        log_issue(options.merge(
            platform_name: platform,
            platform_type: platform_type,
            response:      response
        ))
    end

    # Logs the existence of a remote file as an issue.
    #
    # @param    [HTTP::Response]    response
    # @param    [Bool]      silent
    #   If `false`, a message will be printed to stdout containing the status of
    #   the operation.
    #
    # @see #log_issue
    def log_remote_file( response, silent = false )
        log_issue(
            vector:   Element::Server.new( response ),
            response: response
        )

        print_ok( "Found #{response.url}" ) if !silent
    end
    alias :log_remote_directory :log_remote_file

    # Helper method for issue logging.
    #
    # @param    [Hash]  options {Issue} options.
    #
    # @see #issue
    # @see Arachni::Check::Base#register_results
    def log_issue( options )
        register_results([ self.class.create_issue( options ) ])
    end

    # Just a delegator, logs an array of issues.
    #
    # @param    [Array<Arachni::Issue>]     issues
    #
    # @see Arachni::Check::Manager#register_results
    def register_results( issues )
        return if issue_limit_reached?
        self.class.issue_counter += issues.size

        framework.checks.register_results( issues )
    end

    # @see Arachni::Check::Base#preferred
    # @see Arachni::Check::Base.prefer
    # @abstract
    def preferred
        []
    end

    # This is called right before an {Arachni::Element} is audited and is used
    # to determine whether to skip it or not.
    #
    # Running checks can override this as they wish *but* at their own peril.
    #
    # @param    [Arachni::Element]  elem
    #
    # @return   [Boolean]
    #   `true` if the element should be skipped, `false` otherwise.
    def skip?( elem )
        # Don't audit elements which have been already logged as vulnerable
        # either by us or preferred checks.
        (preferred | [shortname]).each do |mod|
            next if !framework.checks.include?( mod )
            issue_id = framework.checks[mod].create_issue( vector: elem ).unique_id
            return true if framework.checks.issue_set.include?( issue_id )
        end

        false
    end

    # Passes each element prepared for audit to the block.
    #
    # If no element types have been specified in `opts`, it will use the elements
    # from the check's {Base.info} hash.
    #
    # If no elements have been specified in `opts` or {Base.info}, it will use the
    # elements in {OPTIONS}.
    #
    # @param  [Array]    types
    #   Element types to audit (see {OPTIONS}`[:elements]`).
    #
    # @yield       [element]  Each candidate element.
    # @yieldparam [Arachni::Element]
    def each_candidate_element( types = [], &block )
        types = self.class.info[:elements] if types.empty?
        types = OPTIONS[:elements]         if types.empty?

        types.each do |elem|
            elem = elem.type
            next if !Options.audit?( elem )

            case elem
                when Element::Link.type
                    prepare_each_element( page.links, &block )

                when Element::Form.type
                    prepare_each_element( page.forms, &block )

                when Element::Cookie.type
                    prepare_each_element(page.cookies, &block )

                when Element::Header.type
                    prepare_each_element( page.headers, &block )

                when Element::Body.type
                else
                    fail ArgumentError, "Unknown element: #{elem}"
            end
        end
    end

    # If a block has been provided it calls {Arachni::Element::Capabilities::Auditable#audit}
    # for every element, otherwise, it defaults to {#audit_taint}.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable#audit
    # @see #audit_taint
    def audit( payloads, opts = {}, &block )
        opts = OPTIONS.merge( opts )
        if !block_given?
            audit_taint( payloads, opts )
        else
            each_candidate_element( opts[:elements] ) { |e| e.audit( payloads, opts, &block ) }
        end
    end

    # Provides easy access to element auditing using simple taint analysis
    # and automatically logs results.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable::Taint
    def audit_taint( payloads, opts = {} )
        opts = OPTIONS.merge( opts )
        each_candidate_element( opts[:elements] ) { |e| e.taint_analysis( payloads, opts ) }
    end

    # Audits elements using differential analysis and automatically logs results.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable::Differential
    def audit_differential( opts = {}, &block )
        opts = OPTIONS.merge( opts )
        each_candidate_element( opts[:elements] ) { |e| e.differential_analysis( opts, &block ) }
    end

    # Audits elements using timing attacks and automatically logs results.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see OPTIONS
    # @see Arachni::Element::Capabilities::Auditable::Timeout
    def audit_timeout( payloads, opts = {} )
        opts = OPTIONS.merge( opts )
        each_candidate_element( opts[:elements] ) { |e| e.timeout_analysis( payloads, opts ) }
    end

    private

    def prepare_each_element( elements, &block )
        elements.each do |e|
            next if e.inputs.empty?

            d = e.dup
            d.auditor = self
            block.call d
        end
    end

    # Helper `Set` for checks which want to keep track of what they've audited
    # by themselves.
    #
    # @return   [Set]
    #
    # @see #audited?
    # @see #audited
    def self.audited
        @audited ||= Support::LookUp::HashSet.new
    end

end

end
end
