=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Check

# Included by {Check::Base} and provides helper audit methods to all checks.
#
# There are 3 main types of audit and analysis techniques available:
#
# * {Arachni::Element::Capabilities::Analyzable::Signature Signature analysis}
#   -- {#audit}
# * {Arachni::Element::Capabilities::Analyzable::Timeout Timeout analysis}
#   -- {#audit_timeout}
# * {Arachni::Element::Capabilities::Analyzable::Differential Differential analysis}
#   -- {#audit_differential}
#
# It should be noted that actual analysis takes place at the {Arachni::Element element} level.
#
# It also provides:
#
# * Discovery helpers for checking and logging the existence of remote files.
#   * {#log_remote_file}
#   * {#log_remote_file_if_exists}
# * Pattern matching helpers for checking and logging the existence of strings
#   in responses or in the body of the page that's being audited.
#   * {#match_and_log}
# * General {Arachni::Issue} logging helpers.
#   * {#log}
#   * {#log_issue}
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Auditor
    def self.reset
        audited.clear
    end

    def self.has_timeout_candidates?
        Element::Capabilities::Analyzable.has_timeout_candidates?
    end
    def self.timeout_audit_run
        Element::Capabilities::Analyzable.timeout_audit_run
    end

    # @param    [#to_s]  id
    #   Identifier of the object to be marked as audited.
    #
    # @see #audited?
    def audited( id )
        Auditor.audited << "#{self.class}-#{id}"
    end

    # @param    [#to_s] id
    #   Identifier of the object to be checked.
    #
    # @return   [Bool]
    #   `true` if audited, `false` otherwise.
    #
    # @see #audited
    def audited?( id )
        Auditor.audited.include?( "#{self.class}-#{id}" )
    end

    def self.included( m )
        m.class_eval do

            # Determines whether or not to run the check against the given page
            # depending on which elements exist in the page, which elements the
            # check is configured to audit and user options.
            #
            # @param    [Page]    page
            # @param    [Element::Base, Array<Element::Base>]    restrict_to_elements
            #   Element types to check for.
            #
            # @return   [Bool]
            def self.check?( page, restrict_to_elements = nil, ignore_dom_depth = false )
                return false if issue_limit_reached?
                return true  if elements.empty?

                audit                = Arachni::Options.audit
                restrict_to_elements = [restrict_to_elements].flatten.compact

                # We use procs to make the decisions to avoid loading the page
                # element caches unless it's absolutely necessary.
                #
                # Also, it's better to audit Form & Cookie DOM elements only
                # after the page has gone through the browser, because then
                # we'll have some context in the metadata which can help us
                # optimize DOM audits.
                {
                    Element::Link              =>
                        proc { audit.links?     && !!page.links.find { |e| e.inputs.any? } },
                    Element::Link::DOM         =>
                        proc { audit.link_doms? && !!page.links.find(&:dom) },
                    Element::Form              =>
                        proc { audit.forms? && !!page.forms.find { |e| e.inputs.any? } },
                    Element::Form::DOM         =>
                        proc { (ignore_dom_depth || page.dom.depth > 0) &&
                            audit.form_doms? && page.has_script? && !!page.forms.find(&:dom) },
                    Element::Cookie            =>
                        proc { audit.cookies? && page.cookies.any? },
                    Element::Cookie::DOM       =>
                        proc { (ignore_dom_depth || page.dom.depth > 0) &&
                            audit.cookie_doms? && page.has_script? && page.cookies.any? },
                    Element::Header            =>
                        proc { audit.headers? && page.headers.any? },
                    Element::LinkTemplate      =>
                        proc { audit.link_templates? && page.link_templates.find { |e| e.inputs.any? } },
                    Element::LinkTemplate::DOM =>
                        proc { audit.link_template_doms? && !!page.link_templates.find(&:dom) },
                    Element::JSON              =>
                        proc { audit.jsons? && page.jsons.find { |e| e.inputs.any? } },
                    Element::XML               =>
                        proc { audit.xmls? && page.xmls.find { |e| e.inputs.any? } },
                    Element::UIInput             => false,
                    Element::UIInput::DOM        =>
                        proc { audit.ui_inputs? && page.ui_inputs.any? },
                    Element::UIForm            => false,
                    Element::UIForm::DOM       =>
                        proc { audit.ui_forms? && page.ui_forms.any? },
                    Element::Body              => !page.body.empty?,
                    Element::GenericDOM        => page.has_script?,
                    Element::Path              => true,
                    Element::Server            => true
                }.each do |type, decider|
                    next if restrict_to_elements.any? && !restrict_to_elements.include?( type )

                    return true if elements.include?( type ) &&
                        (decider.is_a?( Proc ) ? decider.call : decider)
                end

                false
            end

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

            # Populates and logs an {Arachni::Issue}.
            #
            # @param    [Hash]  options
            #   {Arachni::Issue} initialization options.
            #
            # @return   [Issue]
            def self.log( options )
                options       = options.dup
                vector        = options[:vector]
                audit_options = vector.respond_to?( :audit_options ) ?
                    vector.audit_options : {}

                if options[:referring_page]
                    referring_page = options[:referring_page]
                elsif vector.page
                    referring_page = vector.page
                else
                    fail ArgumentError, 'Missing :referring_page option.'
                end

                if options[:response]
                    page = options.delete(:response).to_page
                elsif options[:page]
                    page = options.delete(:page)
                else
                    page = referring_page
                end

                # Don't check the page scope, the check may have exceeded the DOM depth
                # limit but the check is allowed to do that, only check for an out of
                # scope response.
                return if !page.response.parsed_url.seed_in_host? && page.response.scope.out?

                msg = "In #{vector.type}"

                active = vector.respond_to?( :affected_input_name ) && vector.affected_input_name

                if active
                    msg << " input '#{vector.affected_input_name}'"
                elsif vector.respond_to?( :inputs )
                    msg << " with inputs '#{vector.inputs.keys.join(', ')}'"
                end

                vector.print_ok "#{msg} with action #{vector.action}"

                if Arachni::UI::Output.verbose?
                    if active
                        vector.print_verbose "Injected:  #{vector.affected_input_value.inspect}"
                    end

                    if options[:signature]
                        vector.print_verbose "Signature: #{options[:signature]}"
                    end

                    if options[:proof]
                        vector.print_verbose "Proof:     #{options[:proof]}"
                    end

                    if page.dom.transitions.any?
                        vector.print_verbose 'DOM transitions:'
                        page.dom.print_transitions( method(:print_verbose), '    ' )
                    end

                    if !(request_dump = page.request.to_s).empty?
                        vector.print_verbose "Request: \n#{request_dump}"
                    end

                    vector.print_verbose( '---------' ) if only_positives?
                end

                # Platform identification by vulnerability.
                platform_type = nil
                if (platform = (options.delete(:platform) || audit_options[:platform]))
                    Platform::Manager[vector.action] << platform if Options.fingerprint?
                    platform_type = Platform::Manager[vector.action].find_type( platform )
                end

                log_issue(options.merge(
                    platform_name:  platform,
                    platform_type:  platform_type,
                    page:           page,
                    referring_page: referring_page
                ))
            end

            # Helper method for issue logging.
            #
            # @param    [Hash]  options
            #   {Issue} options.
            #
            # @return   [Issue]
            #
            # @see .create_issue
            def self.log_issue( options )
                return if issue_limit_reached?
                self.issue_counter += 1

                issue = create_issue( options )
                Data.issues << issue
                issue
            end

            # Helper method for creating an issue.
            #
            # @param    [Hash]  options
            #   {Issue} options.
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

    FILE_SIGNATURES_PER_PLATFORM =
        Arachni::Element::Capabilities::Analyzable::Signature::FILE_SIGNATURES_PER_PLATFORM

    FILE_SIGNATURES =
        Arachni::Element::Capabilities::Analyzable::Signature::FILE_SIGNATURES

    SOURCE_CODE_SIGNATURES_PER_PLATFORM =
        Arachni::Element::Capabilities::Analyzable::Signature::SOURCE_CODE_SIGNATURES_PER_PLATFORM

    # Holds constant bitfields that describe the preferred formatting of
    # injection strings.
    Format = Element::Capabilities::Mutable::Format

    # Non-DOM auditable elements.
    ELEMENTS_WITH_INPUTS = [
        Element::Link, Element::Form, Element::Cookie, Element::Header,
        Element::LinkTemplate, Element::JSON, Element::XML
    ]

    # Auditable DOM elements.
    DOM_ELEMENTS_WITH_INPUTS = [
        Element::Link::DOM, Element::Form::DOM, Element::Cookie::DOM,
        Element::LinkTemplate::DOM, Element::UIInput::DOM, Element::UIForm::DOM
    ]

    # @return   [Arachni::Page]
    #   Page object to be audited.
    attr_reader :page

    # @return   [Arachni::Framework]
    attr_reader :framework

    # @param  [Page]        page
    # @param  [Framework]  framework
    def initialize( page, framework )
        @page      = page
        @framework = framework
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
    # @see Element::Server#remote_file_exist?
    def log_remote_file_if_exists( url, silent = false, options = {}, &block )
        @server ||= Element::Server.new( page.url ).tap { |s| s.auditor = self }
        @server.log_remote_file_if_exists( url, silent, options, &block )
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
        @body ||= Element::Body.new( self.page.url ).tap { |b| b.auditor = self }
        @body.match_and_log( patterns, &block )
    end

    # Logs the existence of a remote file as an issue.
    #
    # @overload log_remote_file( response, silent = false )
    #   @param    [HTTP::Response]    response
    #   @param    [Bool]      silent
    #       If `false`, a message will be printed to stdout containing the status of
    #       the operation.
    #
    # @overload log_remote_file( page, silent = false )
    #   @param    [Page]    page
    #   @param    [Bool]    silent
    #       If `false`, a message will be printed to stdout containing the status of
    #       the operation.
    #
    # @return   [Issue]
    #
    # @see #log_issue
    def log_remote_file( page_or_response, silent = false, options = {} )
        page = page_or_response.is_a?( Page ) ?
            page_or_response : page_or_response.to_page

        issue = log_issue({
            vector: Element::Server.new( page.url ),
            proof:  page.response.status_line,
            page:   page
        }.merge( options ))

        print_ok( "Found #{page.url}" ) if !silent

        issue
    end
    alias :log_remote_directory :log_remote_file

    # Helper method for issue logging.
    #
    # @param    [Hash]  options
    #   {Issue} options.
    #
    # @return   [Issue]
    #
    # @see .create_issue
    def log_issue( options )
        self.class.log_issue( options.merge( referring_page: @page ) )
    end

    # Populates and logs an {Arachni::Issue}.
    #
    # @param    [Hash]  options
    #   {Arachni::Issue} initialization options.
    #
    # @return   [Issue]
    def log( options )
        self.class.log( options.merge( referring_page: @page ) )
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
    # @param    [Arachni::Element]  element
    #
    # @return   [Boolean]
    #   `true` if the element should be skipped, `false` otherwise.
    #
    # @see  Page#audit?
    def skip?( element )
        # This method also gets called from Auditable#audit to check mutations,
        # don't touch these, we're filtering at a higher level here, otherwise
        # we might mess up the audit.
        return true if !element.mutation? && audited?( element.coverage_id )
        return true if !page.audit_element?( element )

        # Don't audit elements which have been already logged as vulnerable
        # either by us or preferred checks.
        (preferred | [shortname]).each do |check|
            next if !framework.checks.include?( check )

            klass = framework.checks[check]
            next if !klass.info.include?(:issue)

            # No point in doing the following heavy deduplication check if there
            # are no issues logged to begin with.
            next if klass.issue_counter == 0

            if Data.issues.include?( klass.create_issue( vector: element ) )
                return true
            end
        end

        false
    end

    # Passes each element prepared for audit to the block.
    #
    # It will use the elements from the check's {Base.info} hash.
    # If no elements have been specified it will use {ELEMENTS_WITH_INPUTS}.
    #
    # @yield       [element]
    #   Each candidate element.
    # @yieldparam [Arachni::Element]
    def each_candidate_element( &block )
        types = self.class.elements
        types = ELEMENTS_WITH_INPUTS if types.empty?

        types.each do |elem|
            elem = elem.type

            next if !Options.audit.elements?( elem )

            case elem
                when Element::Link.type
                    prepare_each_element( page.links, &block )

                when Element::Form.type
                    prepare_each_element( page.forms, &block )

                when Element::Cookie.type
                    prepare_each_element(page.cookies, &block )

                when Element::Header.type
                    prepare_each_element( page.headers, &block )

                when Element::LinkTemplate.type
                    prepare_each_element( page.link_templates, &block )

                when Element::JSON.type
                    prepare_each_element( page.jsons, &block )

                when Element::XML.type
                    prepare_each_element( page.xmls, &block )

                else
                    fail ArgumentError, "Unknown element: #{elem}"
            end
        end
    end

    # Passes each element prepared for audit to the block.
    #
    # It will use the elements from the check's {Base.info} hash.
    # If no elements have been specified it will use {DOM_ELEMENTS_WITH_INPUTS}.
    #
    # @yield       [element]
    #   Each candidate element.
    # @yieldparam [Arachni::Element::DOM]
    def each_candidate_dom_element( &block )
        types = self.class.elements
        types = DOM_ELEMENTS_WITH_INPUTS if types.empty?

        types.each do |elem|
            elem = elem.type

            next if !Options.audit.elements?( elem.to_s.gsub( '_dom', '' ) )

            case elem
                when Element::Link::DOM.type
                    prepare_each_dom_element( page.links, &block )

                when Element::Form::DOM.type
                    prepare_each_dom_element( page.forms, &block )

                when Element::Cookie::DOM.type
                    prepare_each_dom_element( page.cookies, &block )

                when Element::LinkTemplate::DOM.type
                    prepare_each_dom_element( page.link_templates, &block )

                when Element::UIInput::DOM.type
                    prepare_each_dom_element( page.ui_inputs, &block )

                when Element::UIForm::DOM.type
                    prepare_each_dom_element( page.ui_forms, &block )

                else
                    fail ArgumentError, "Unknown DOM element: #{elem}"
            end
        end
    end

    # If a block has been provided it calls {Arachni::Element::Capabilities::Auditable#audit}
    # for every element, otherwise, it defaults to {#audit_signature}.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see Arachni::Element::Capabilities::Auditable#audit
    # @see #audit_signature
    def audit( payloads, opts = {}, &block )
        if !block_given?
            audit_signature( payloads, opts )
        else
            each_candidate_element do |e|
                e.audit( payloads, opts, &block )
                audited( e.coverage_id )
            end
        end
    end

    # Calls {Arachni::Element::Capabilities::Auditable#buffered_audit}
    # for every element.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see Arachni::Element::Capabilities::Auditable#buffered_audit
    def buffered_audit( payloads, opts = {}, &block )
        each_candidate_element do |e|
            e.buffered_audit( payloads, opts, &block )
            audited( e.coverage_id )
        end
    end

    # Provides easy access to element auditing using simple signature analysis
    # and automatically logs results.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see Arachni::Element::Capabilities::Analyzable::Signature
    def audit_signature( payloads, opts = {} )
        each_candidate_element do |e|
            e.signature_analysis( payloads, opts )
            audited( e.coverage_id )
        end
    end

    # Audits elements using differential analysis and automatically logs results.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see Arachni::Element::Capabilities::Analyzable::Differential
    def audit_differential( opts = {}, &block )
        each_candidate_element do |e|
            e.differential_analysis( opts, &block )
            audited( e.coverage_id )
        end
    end

    # Audits elements using timing attacks and automatically logs results.
    #
    # Uses {#each_candidate_element} to decide which elements to audit.
    #
    # @see Arachni::Element::Capabilities::Analyzable::Timeout
    def audit_timeout( payloads, opts = {} )
        each_candidate_element do |e|
            e.timeout_analysis( payloads, opts )
            audited( e.coverage_id )
        end
    end

    # Traces the taint in the given `resource` and passes each page to the
    # `block`.
    #
    # @param    [Page, String, HTTP::Response] resource
    #   Resource to load and whose environment to trace, if given a `String` it
    #   will be treated it as a URL and will be loaded.
    # @param    [Hash]  options
    #   See {BrowserCluster::Jobs::TaintTrace} accessors.
    # @param    [Block] block
    #   Block to handle each page snapshot. If the `block` returns a `true` value,
    #   further analysis will be aborted.
    def trace_taint( resource, options = {}, &block )
        with_browser_cluster do |cluster|
            cluster.trace_taint( resource, options ) do |result|
                block.call( result.page )
            end
        end
    end

    # @param    [Block] block
    #   Block to passed a {BrowserCluster}, if one is available.
    def with_browser_cluster( &block )
        return if !browser_cluster
        block.call browser_cluster
        true
    end

    # @note Operates in non-blocking mode.
    #
    # @param    [Block] block
    #   Block to passed a {BrowserCluster::Worker}, if/when one is available.
    #
    # @see BrowserCluster::Worker#with_browser
    def with_browser( *args, &block )
        with_browser_cluster { |cluster| cluster.with_browser( *args, &block ) }
        true
    end

    private

    def prepare_each_element( elements, &block )
        elements.each do |e|
            next if skip?( e ) || e.inputs.empty?

            d = e.dup
            d.auditor = self
            block.call d
        end
    end

    def prepare_each_dom_element( elements, &block )
        elements.each do |e|
            next if !e.dom || e.dom.inputs.empty? || skip?( e.dom )

            d = e.dup.dom
            d.auditor = self
            block.call d
        end
    end

    # @return   [State::Audit]
    #   Keeps track of audit operations.
    #
    # @see #audited?
    # @see #audited
    def self.audited
        State.audit
    end

end

end
end
