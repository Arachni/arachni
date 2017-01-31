=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'childprocess'
require 'watir-webdriver'
require_relative 'selenium/webdriver/element'
require_relative 'processes/manager'
require_relative 'browser/element_locator'
require_relative 'browser/javascript'

module Arachni

# @note Depends on PhantomJS 2.1.1.
#
# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Browser
    include UI::Output
    include Utilities
    include Support::Mixins::Observable

    # @!method on_fire_event( &block )
    advertise :on_fire_event

    # @!method on_new_page( &block )
    advertise :on_new_page

    # @!method on_new_page_with_sink( &block )
    advertise :on_new_page_with_sink

    # @!method on_response( &block )
    advertise :on_response

    personalize_output

    # {Browser} error namespace.
    #
    # All {Browser} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error

        # Raised when the browser could not be spawned.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class Spawn < Error
        end

        # Raised when a given resource can't be loaded.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class Load < Error
        end
    end

    # How much time to wait for the PhantomJS process to spawn before respawning.
    BROWSER_SPAWN_TIMEOUT = 60

    # How much time to wait for a targeted HTML element to appear on the page
    # after the page is loaded.
    ELEMENT_APPEARANCE_TIMEOUT = 5

    ASSET_EXTENSIONS = Set.new(%w( css js jpg jpeg png gif json ))

    INPUT_EVENTS          = Set.new([
        :change, :blur, :focus, :select, :keyup, :keypress, :keydown, :input
    ])
    INPUT_EVENTS_TO_FORCE = Set.new([
        :focus, :change, :blur, :select
    ])

    ASSET_EXTRACTORS = [
        /<\s*link.*?href=\s*['"]?(.*?)?['"]?[\s>]/im,
        /src\s*=\s*['"]?(.*?)?['"]?[\s>]/i,
    ]

    # Unfortunately, we can't expose the HTTP user-agent for client-side
    # stuff, because Selenium needs to know that we're using a Webkit-based
    # browser in order to use the right JS code to trigger events etc.
    USER_AGENT = 'Mozilla/5.0 AppleWebKit/538.1 (KHTML, like Gecko) ' <<
        "Arachni/#{Arachni::VERSION} Safari/538.1"

    # @return   [Array<Page::DOM::Transition>]
    attr_reader :transitions

    # @return   [Hash]
    #   Preloaded resources, by URL.
    attr_reader :preloads

    attr_reader :proxy

    # @return   [Watir::Browser]
    #   Watir driver interface.
    attr_reader :watir

    # @return   [Selenium::WebDriver]
    #   Selenium driver interface.
    attr_reader :selenium

    # @return   [Array<Page>]
    #   Same as {#page_snapshots} but it doesn't deduplicate and only contains
    #   pages with sink ({Page::DOM#data_flow_sinks} or {Page::DOM#execution_flow_sinks})
    #   data as populated by {Javascript#data_flow_sinks} and {Javascript#execution_flow_sinks}.
    #
    # @see Javascript#data_flow_sinks
    # @see Javascript#execution_flow_sinks
    # @see Page::DOM#data_flow_sinks
    # @see Page::DOM#execution_flow_sinks
    attr_reader :page_snapshots_with_sinks

    # @return   [Javascript]
    attr_reader :javascript

    # @return   [Support::LookUp::HashSet]
    #   States that have been visited and should be skipped.
    #
    # @see #skip_state
    # @see #skip_state?
    attr_reader :skip_states

    # @return   [Integer]
    #   PID of the lifeline process managing the browser process.
    attr_reader :lifeline_pid

    # @return   [Integer]
    #   PID of the browser process.
    attr_reader :browser_pid

    attr_reader :last_url

    class <<self

        # @return   [Bool]
        #   `true` if a supported browser is in the OS PATH, `false` otherwise.
        def has_executable?
            !!executable
        end

        # @return   [String]
        #   Path to the PhantomJS executable.
        def executable
            Selenium::WebDriver::PhantomJS.path
        end

        def asset_domains
            @asset_domains ||= Set.new
        end

        def add_asset_domain( url )
            return if url.to_s.empty?
            return if !(curl = Arachni::URI( url ))
            return if !(domain = curl.domain)

            asset_domains << domain
            domain
        end

    end
    asset_domains

    # @param    [Hash]  options
    # @option options   [Integer]    :concurrency
    #   Maximum number of concurrent connections.
    # @option   options [Bool] :store_pages  (true)
    #   Whether to store pages in addition to just passing them to {#on_new_page}.
    # @option   options [Integer] :width  (1600)
    #   Window width.
    # @option   options [Integer] :height  (1200)
    #   Window height.
    def initialize( options = {} )
        super()
        @options = options.dup

        @ignore_scope = options[:ignore_scope]

        @width  = options[:width]  || 1600
        @height = options[:height] || 1200

        @options[:store_pages] = true if !@options.include?( :store_pages )

        start_webdriver

        # User-controlled preloaded responses, by URL.
        @preloads = {}

        # Captured pages -- populated by #capture.
        @captured_pages = []

        # Snapshots of the working page resulting from firing of events and
        # clicking of JS links.
        @page_snapshots = {}

        # Same as @page_snapshots but it doesn't deduplicate and only contains
        # pages with sink (Page::DOM#sink) data as populated by Javascript#flush_sink.
        @page_snapshots_with_sinks = []

        # Captures HTTP::Response objects per URL for open windows.
        @window_responses = {}


        # Keeps track of resources which should be skipped -- like already fired
        # events and clicked links etc.
        @skip_states = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        @transitions = []
        @request_transitions = []
        @add_request_transitions = true

        # Last loaded URL.
        @last_url = nil

        @javascript = Javascript.new( self )
    end

    def clear_buffers
        synchronize do
            @preloads.clear
            @captured_pages.clear
            @page_snapshots.clear
            @page_snapshots_with_sinks.clear
            @window_responses.clear
        end
    end

    # @return   [String]
    #   Prefixes each source line with a number.
    def source_with_line_numbers
        source.lines.map.with_index do |line, i|
            "#{i+1} - #{line}"
        end.join
    end

    # @param    [String, HTTP::Response, Page, Page:::DOM]  resource
    #   Loads the given resource in the browser. If it is a string it will be
    #   treated like a URL.
    #
    # @return   [Browser]
    #   `self`
    def load( resource, options = {} )

        case resource
            when String
                @transitions = []
                goto resource, options

            when HTTP::Response
                @transitions = []
                goto preload( resource ), options

            when Page
                HTTP::Client.update_cookies resource.cookie_jar

                load resource.dom

            when Page::DOM
                @transitions = resource.transitions.dup
                update_skip_states resource.skip_states

                @add_request_transitions = false if @transitions.any?
                resource.restore self
                @add_request_transitions = true

            else
                fail Error::Load,
                     "Can't load resource of type #{resource.class}."
        end

        self
    end

    # @note The preloaded resource will be removed once used.
    #
    # @param    [HTTP::Response, Page]  resource
    #   Preloads a resource to be instantly available by URL via {#load}.
    def preload( resource )
        response =  case resource
                        when HTTP::Response
                            resource

                        when Page
                            resource.response

                        else
                            fail Error::Load,
                                 "Can't preload resource of type #{resource.class}."
                    end

        save_response( response ) if !response.url.include?( request_token )

        @preloads[response.url] = response
        response.url
    end

    # @param    [String]  url
    #   Loads the given URL in the browser.
    # @param    [Hash]  options
    # @option  [Bool]  :take_snapshot  (true)
    #   Take a snapshot right after loading the page.
    # @option  [Array<Cookie>]  :cookies  ([])
    #   Extra cookies to pass to the webapp.
    #
    # @return   [Page::DOM::Transition]
    #   Transition used to replay the resource visit.
    def goto( url, options = {} )
        take_snapshot      = options.include?(:take_snapshot) ?
            options[:take_snapshot] : true
        extra_cookies      = options[:cookies] || {}
        update_transitions = options.include?(:update_transitions) ?
            options[:update_transitions] : true

        pre_add_request_transitions = @add_request_transitions
        if !update_transitions
            @add_request_transitions = false
        end

        @last_url = Arachni::URI( url ).to_s
        self.class.add_asset_domain @last_url

        ensure_open_window

        load_cookies url, extra_cookies

        transition = Page::DOM::Transition.new( :page, :load,
            url:     url,
            cookies: extra_cookies
        ) do
            print_debug_level_2 "Loading #{url} ..."
            @selenium.navigate.to url
            print_debug_level_2 '...done.'

            wait_till_ready

            Options.browser_cluster.css_to_wait_for( url ).each do |css|
                print_info "Waiting for #{css.inspect} to appear for: #{url}"

                begin
                    Selenium::WebDriver::Wait.new(
                        timeout: Options.browser_cluster.job_timeout
                    ).until { @selenium.find_element( :css, css ) }

                    print_info "#{css.inspect} appeared for: #{url}"
                rescue Selenium::WebDriver::Error::TimeOutError
                    print_bad "#{css.inspect} did not appear for: #{url}"
                end

            end

            javascript.set_element_ids
        end

        if @add_request_transitions
            @transitions << transition
        end

        @add_request_transitions = pre_add_request_transitions

        update_cookies

        # Capture the page at its initial state.
        capture_snapshot if take_snapshot

        transition
    end

    def wait_till_ready
        @javascript.wait_till_ready
        wait_for_timers
        wait_for_pending_requests
    end

    def shutdown
        print_debug 'Shutting down...'

        print_debug_level_2 'Killing process.'
        if @kill_process
            begin
                @kill_process.close
            rescue => e
                print_debug_exception e
            end
        end

        print_debug_level_2 'Shutting down proxy...'
        @proxy.shutdown rescue Reactor::Error::NotRunning
        print_debug_level_2 '...done.'

        @proxy        = nil
        @kill_process = nil
        @watir        = nil
        @selenium     = nil
        @lifeline_pid = nil
        @browser_pid  = nil
        @browser_url  = nil

        print_debug '...shutdown complete.'
    end

    # @return   [String]
    #   Current URL, noralized via #{Arachni::URI.}
    def url
        normalize_url dom_url
    end

    # @return   [String]
    #   Current URL, as provided by the browser.
    def dom_url
        @selenium.current_url
    end

    # Explores the browser's DOM tree and captures page snapshots for each
    # state change until there are no more available.
    #
    # @param    [Integer]   depth
    #   How deep to go into the DOM tree.
    #
    # @return   [Array<Page>]
    #   Page snapshots for each state.
    def explore_and_flush( depth = nil )
        pages         = [ to_page ]
        current_depth = 0

        loop do
            bcnt   = pages.size
            pages |= pages.map { |p| load( p ).trigger_events.flush_pages }.flatten

            break if pages.size == bcnt || (depth && depth >= current_depth)

            current_depth += 1
        end

        pages.compact
    end

    # @note Will skip non-visible elements as they can't be manipulated.
    #
    # Iterates over all elements which have events and passes their info to the
    # given block.
    #
    # @yield    [ElementLocator,Array<Symbol>]
    #   Element locator along with the element's applicable events along with
    #   their handlers and attributes.
    def each_element_with_events( whitelist = [])
        current_url = self.url

        javascript.each_dom_element_with_events whitelist do |element|
            tag_name   = element['tag_name']
            attributes = element['attributes']
            events     = element['events']

            case tag_name
                when 'a'
                    href = attributes['href'].to_s

                    if !href.empty?
                        if href.downcase.start_with?( 'javascript:' )
                            (events[:click] ||= []) << href
                        else
                            next if skip_path?( to_absolute( href, current_url ) )
                        end
                    end

                when 'input'
                    if attributes['type'].to_s.downcase == 'image'
                        (events[:click] ||= []) << 'image'
                    end

                when 'form'
                    action = attributes['action'].to_s

                    if !action.empty?
                        if action.downcase.start_with?( 'javascript:' )
                            (events[:submit] ||= []) << action
                        else
                            next if skip_path?( to_absolute( action, current_url ) )
                        end
                    end
            end

            next if events.empty?

            yield ElementLocator.new( tag_name: tag_name, attributes: attributes ),
                    events
        end

        self
    end

    # Triggers all events on all elements (**once**) and captures
    # {#page_snapshots page snapshots}.
    #
    # @return   [Browser]
    #   `self`
    def trigger_events
        dom = self.state
        return self if !dom

        url = normalize_url( dom.url )

        count = 1
        each_element_with_events do |locator, events|
            state = "#{url}:#{locator.tag_name}:#{locator.attributes}:#{events.keys.sort}"
            next if skip_state?( state )
            skip_state state

            events.each do |name, _|
                if Options.scope.dom_event_limit_reached?( count )
                    print_debug "DOM event limit reached for: #{dom.url}"
                    next
                end

                distribute_event( dom, locator, name.to_sym )

                count += 1
            end
        end

        self
    end

    # @note Only used when running as part of {BrowserCluster} to distribute
    #   page analysis across a pool of browsers.
    #
    # Distributes the triggering of `event` on the element at `element_index`
    # on `page`.
    #
    # @param    [String, Page, Page::DOM, HTTP::Response]    resource
    # @param    [ElementLocator]  locator
    # @param    [Symbol]  event
    def distribute_event( resource, locator, event )
        trigger_event( resource, locator, event )
    end

    # @note Captures page {#page_snapshots}.
    #
    # Triggers `event` on the element described by `tag` on `page`.
    #
    # @param    [String, Page, Page::DOM, HTTP::Response]    resource
    #   Page containing the element's `tag`.
    # @param    [ElementLocator]  element
    # @param    [Symbol]  event
    #   Event to trigger.
    def trigger_event( resource, element, event, restore = true )
        transition = fire_event( element, event )

        if !transition
            print_info "Could not trigger '#{event}' on: #{element}"

            if restore
                print_info 'Restoring page.'
                restore( resource )
            end

            return
        end

        capture_snapshot( transition )
        restore( resource ) if restore
    end

    # Triggers `event` on `element`.
    #
    # @param    [Selenium::WebDriver::Element, ElementLocator]  element
    # @param    [Symbol]  event
    # @param    [Hash]  options
    # @option options [Hash<Symbol,String=>String>]  :inputs
    #   Values to use to fill-in inputs. Keys should be input names or ids.
    #
    #   Defaults to using {OptionGroups::Input} if not specified.
    #
    # @return   [Page::DOM::Transition, false]
    #   Transition if the operation was successful, `nil` otherwise.
    def fire_event( element, event, options = {} )
        event   = event.to_s.downcase.sub( /^on/, '' ).to_sym
        locator = nil

        options[:inputs] = options[:inputs].my_stringify if options[:inputs]

        if element.is_a? ElementLocator
            locator = element

            begin
                Selenium::WebDriver::Wait.new( timeout: ELEMENT_APPEARANCE_TIMEOUT ).
                    until { element = element.locate( self ) }

            rescue Selenium::WebDriver::Error::WebDriverError => e
                print_debug "Element '#{element.inspect}' could not be " <<
                                "located for triggering '#{event}'."
                print_debug
                print_debug_exception e
                return
            end
        end

        if locator
            opening_tag = locator.to_s
            tag_name    = locator.tag_name
        else
            opening_tag = element.opening_tag
            tag_name    = element.tag_name
            locator     = ElementLocator.from_html( opening_tag )
        end

        print_debug_level_2 "[start]: #{event} (#{options}) #{locator}"

        tag_name = tag_name.to_sym

        notify_on_fire_event( element, event )

        pre_timeouts = javascript.timeouts

        begin
            transition = Page::DOM::Transition.new( locator, event, options ) do
                force = true

                # It's better to use the helpers whenever possible instead of
                # firing events manually.
                if tag_name == :form
                    fill_in_form_inputs( element, options[:inputs] )

                    if event == :fill
                        force = false
                    end

                    if event == :submit
                        force = false

                        begin
                            element.find_elements( :css,
                                "input[type='submit'], button[type='submit']"
                            ).first.click
                        rescue => e
                            print_debug "No submit button, will trigger 'submit' event."
                            print_debug_exception e

                            element.submit
                        end
                    end

                elsif event == :click
                    force = false

                    element.click

                elsif INPUT_EVENTS.include? event
                    force = INPUT_EVENTS_TO_FORCE.include?( event )

                    # Send keys will append to the existing value, so we need to
                    # clear it first. The receiving input may not support values
                    # though, so watch out.
                    element.clear if [:input, :textarea].include?( tag_name )

                    # Simulates real text input and will trigger associated events.
                    # Except for INPUT_EVENTS_TO_FORCE of course.
                    element.send_keys( (options[:value] || value_for( element )).to_s )
                end

                if force
                    print_debug_level_2 "[forcing event]: #{event} (#{options}) #{locator}"
                    fire_event_js locator, event
                end

                print_debug_level_2 "[waiting for requests]: #{event} (#{options}) #{locator}"
                wait_for_pending_requests
                print_debug_level_2 "[done waiting for requests]: #{event} (#{options}) #{locator}"

                # Maybe we switched to a different page, wait until the custom
                # JS env has been put in place.
                javascript.wait_till_ready
                javascript.set_element_ids

                update_cookies
            end

            print_debug_level_2 "[done in #{transition.time}s]: #{event} (#{options}) #{locator}"

            delay = (javascript.timeouts - pre_timeouts).compact.map { |t| t[1].to_i }.max
            if delay
                print_debug_level_2 "Found new timers with max #{delay}ms."
                delay = [Options.http.request_timeout, delay].min / 1000.0

                print_debug_level_2 "Will wait for #{delay}s."
                sleep delay
            end

            transition
        rescue Selenium::WebDriver::Error::WebDriverError => e

            print_debug "Error when triggering event for: #{dom_url}"
            print_debug "-- '#{event}' on: #{opening_tag} -- #{locator.css}"
            print_debug
            print_debug_exception e
            nil
        end
    end

    # This is essentially the same thing as Watir::Element#fire_event
    # but 10 times faster.
    #
    # Does not perform any sort of sanitization nor sanity checking, it will
    # just try to trigger the event.
    #
    # @param    [Browser::ElementLocator]   locator
    # @param    [Symbol,String]   event
    # @param    [Numeric]   wait
    #   Amount of time to wait (in seconds) after triggering the event.
    def fire_event_js( locator, event, wait: 0.1 )
        r = javascript.run <<-EOJS
            var element = document.querySelector( #{locator.css.inspect} );

            // Could not be found.
            if( !element ) return false;

            // Invisible.
            if( element.offsetWidth <= 0 && element.offsetHeight <= 0 ) return false;

            var event = document.createEvent( "Events" );

            event.initEvent( "#{event}", true, true );

            event.view     = window;
            event.altKey   = false;
            event.ctrlKey  = false;
            event.shiftKey = false;
            event.metaKey  = false;
            event.keyCode  = 0;
            event.charCode = 'a';

            element.dispatchEvent( event );

            return true;
        EOJS

        sleep( wait ) if r

        r
    end

    # Starts capturing requests and parses them into elements of pages,
    # accessible via {#captured_pages}.
    #
    # @return   [Browser]
    #   `self`
    #
    # @see #stop_capture
    # @see #capture?
    # @see #captured_pages
    # @see #flush_pages
    def start_capture
        @capture = true
        self
    end

    # Stops the {HTTP::Request} capture.
    #
    # @return   [Browser]
    #   `self`
    #
    # @see #start_capture
    # @see #capture?
    # @see #flush_pages
    def stop_capture
        @capture = false
        self
    end

    # @return   [Bool]
    #   `true` if request capturing is enabled, `false` otherwise.
    #
    # @see #start_capture
    # @see #stop_capture
    def capture?
        !!@capture
    end

    # @return   [Array<Page>]
    #   Page snapshots (stored after events have been fired and JS links clicked)
    #   with hashes as keys and pages as values.
    def page_snapshots
        @page_snapshots.values
    end

    # @return   [Array<Page>]
    #   Captured HTTP requests performed by the web page (AJAX etc.) converted
    #   into forms of pages to assist with analysis and audit.
    def captured_pages
        @captured_pages
    end

    # @return   [Page::DOM]
    def state
        d_url = dom_url

        return if !response

        Page::DOM.new(
            url:         d_url,
            transitions: @transitions.dup,
            digest:      @javascript.dom_digest,
            skip_states: skip_states.dup
        )
    end

    # @return   [Page]
    #   Converts the current browser window to a {Page page}.
    def to_page
        d_url = dom_url

        if !(r = response)
            return Page.from_data(
                dom: {
                    url: d_url
                },
                response: {
                    code: 0,
                    url:  url
                }
            )
        end

        # We need sink data for both the current taint and to determine cookie
        # usage, so grab all of the data-flow sinks once.
        data_flow_sinks = {}
        if @javascript.supported?
            data_flow_sinks = @javascript.taint_tracer.data_flow_sinks
        end

        page                          = r.to_page
        page.body                     = source
        page.dom.url                  = d_url
        page.dom.cookies              = self.cookies
        page.dom.digest               = @javascript.dom_digest
        page.dom.execution_flow_sinks = @javascript.execution_flow_sinks
        page.dom.data_flow_sinks      = data_flow_sinks[@javascript.taint] || []
        page.dom.transitions          = @transitions.dup
        page.dom.skip_states          = skip_states.dup

        if Options.audit.ui_inputs?
            page.ui_inputs = Element::UIInput.from_browser( self, page )
        end

        if Options.audit.ui_forms?
            page.ui_forms = Element::UIForm.from_browser( self, page )
        end

        # Go through auditable DOM forms and cookies and remove the DOM from
        # them if no events are associated with it.
        #
        # This can save **A LOT** of time during the audit.
        if @javascript.supported?
            if Options.audit.form_doms?
                page.forms.each do |form|
                    next if !form.node || !form.dom

                    action = form.node['action'].to_s
                    form.dom.browser = self

                    next if action.downcase.start_with?( 'javascript:' ) ||
                        form.dom.locate.events.any?

                    form.skip_dom = true
                end

                page.update_metadata
                page.clear_cache
            end

            if Options.audit.cookie_doms?
                page.cookies.each do |cookie|
                    if (sinks = data_flow_sinks[cookie.name] ||
                        data_flow_sinks[cookie.value])

                        # Don't be satisfied with just a taint match, make sure
                        # the full value is identical.
                        #
                        # For example, if a cookie has '1' as a name or value
                        # that's too generic and can match irrelevant data.
                        #
                        # The current approach isn't perfect of course, but it's
                        # the best we can do.
                        next if sinks.find do |sink|
                            sink.tainted_value == cookie.name ||
                                sink.tainted_value == cookie.value
                        end
                    end

                    cookie.skip_dom = true
                end

                page.update_metadata
            end
        end

        page
    end

    def capture_snapshot( transition = nil )
        pages = []

        request_transitions = flush_request_transitions
        transitions = ([transition] + request_transitions).flatten.compact

        window_handles = @selenium.window_handles

        begin
            window_handles.each do |handle|
                if window_handles.size > 1
                    @selenium.switch_to.window( handle )
                end

                # We don't even have an HTTP response for the page, don't
                # bother trying anything else.
                next if !response

                unique_id = javascript.dom_event_digest
                already_seen = skip_state?( unique_id )
                skip_state unique_id

                with_sinks = javascript.has_sinks?

                # Avoid a #to_page call if at all possible because it'll generate
                # loads of data.
                next if (already_seen && !with_sinks) ||
                    (page = to_page).code == 0

                if pages.empty?
                    transitions.each do |t|
                        @transitions << t
                        page.dom.push_transition t
                    end
                end

                capture_snapshot_with_sink( page )

                next if already_seen

                # Safegued against pages which generate an inf number of DOM
                # states regardless of UI interactions.
                transition_id ="#{page.dom.url}:#{page.dom.playable_transitions.map(&:hash)}"
                transition_id_seen = skip_state?( transition_id )
                skip_state transition_id
                next if transition_id_seen

                notify_on_new_page( page )

                if store_pages?
                    @page_snapshots[unique_id] = page
                    pages << page
                end
            end
        rescue => e
            print_debug "Could not capture snapshot for: #{@last_url}"

            if transition
                print_debug "-- #{transition}"
            end

            print_debug
            print_debug_exception e
        ensure
            @selenium.switch_to.default_content
        end

        pages
    end

    # @return   [Array<Page>]
    #   Returns {#page_snapshots_with_sinks} and flushes it.
    def flush_page_snapshots_with_sinks
        @page_snapshots_with_sinks.dup
    ensure
        @page_snapshots_with_sinks.clear
    end

    # @return   [Array<Page>]
    #   Flushes and returns the {#captured_pages captured} and
    #   {#page_snapshots snapshot} pages.
    #
    # @see #captured_pages
    # @see #page_snapshots
    # @see #start_capture
    # @see #stop_capture
    # @see #capture?
    def flush_pages
        captured_pages + page_snapshots
    ensure
        @captured_pages.clear
        @page_snapshots.clear
    end

    # @return   [Array<Cookie>]
    #   Cookies visible to JS.
    def cookies
        js_cookies = begin
             # Watir doesn't tell us if cookies are HttpOnly, so we need to figure
             # this out ourselves, by checking for JS visibility.
            javascript.run( 'return document.cookie' )
        # We may not have a page.
        rescue Selenium::WebDriver::Error::WebDriverError
            ''
        end

        # The domain attribute cannot be trusted, PhantomJS thinks all cookies
        # are for subdomains too.
        # Do not try to hack around this because it'll be a waste of time,
        # leading to confusion and duplicate cookies.
        #
        # Still, we ask Selenium for cookies instead of parsing the JS ones
        # and merging with the HTTP cookiejar because this allows us to get
        # a path attribute for JS cookies.
        @selenium.manage.all_cookies.map do |c|

            c[:httponly] = !js_cookies.include?( c[:name].to_s )
            c[:path]     = c[:path].gsub( /\/+/, '/' )
            c[:expires]  = Time.parse( c[:expires].to_s ) if c[:expires]

            c[:raw_name]  = c[:name].to_s
            c[:raw_value] = c[:value].to_s

            c[:name]  = Cookie.decode( c[:name].to_s )
            c[:value] = Cookie.value_to_v0( c[:value].to_s )

            Cookie.new c.merge( url: @last_url || self.url )
        end
    end

    def update_cookies
        HTTP::Client.update_cookies self.cookies
    end

    # @return   [String]
    #   HTML code of the evaluated (DOM/JS/AJAX) page.
    def source
        @selenium.page_source
    end

    def load_delay
        #(intervals + timeouts).map { |t| t[1] }.max
        @javascript.timeouts.compact.map { |t| t[1].to_i }.max
    end

    def wait_for_timers
        delay = load_delay
        return if !delay

        effective_delay = [Options.http.request_timeout, delay].min / 1000.0
        print_debug_level_2 "Waiting for max timer #{effective_delay}s (original was #{delay}ms)..."

        sleep effective_delay

        print_debug_level_2 '...done.'
    end

    def skip_path?( path )
        enforce_scope? && super( path )
    end

    def response
        u = dom_url

        if u == 'about:blank'
            print_debug 'Blank page.'
            return
        end

        if skip_path?( u )
            print_debug "Response is out of scope: #{u}"
            return
        end

        r = get_response( u )

        return r if r && r.code != 504

        if r
            print_debug "Origin server timed-out when requesting: #{u}"
        else
            print_debug "Response never arrived for: #{u}"

            print_debug 'Available responses are:'
            @window_responses.each do |k, _|
                print_debug "-- #{k}"
            end

            print_debug 'Tried:'
            print_debug "-- #{u}"
            print_debug "-- #{normalize_url( u )}"
            print_debug "-- #{normalize_watir_url( u )}"
        end

        nil
    end

    # @return   [Selenium::WebDriver::Driver]
    #   Selenium driver interface.
    def selenium
        return @selenium if @selenium

        # For some weird reason the Typhoeus client is very slow for
        # PhantomJS 2.1.1 and causes a boatload of time-outs.
        client = Selenium::WebDriver::Remote::Http::Default.new
        client.timeout = Options.browser_cluster.job_timeout

        @selenium = Selenium::WebDriver.for(
            :remote,

            # We need to spawn our own PhantomJS process because Selenium's
            # way sometimes gives us zombies.
            url:                  spawn_browser,
            desired_capabilities: capabilities,
            http_client:          client
        )
    end

    def alive?
        @lifeline_pid && Processes::Manager.alive?( @lifeline_pid )
    end

    def inspect
        s = "#<#{self.class} "
        s << "pid=#{@lifeline_pid} "
        s << "browser_pid=#{@browser_pid} "
        s << "last-url=#{@last_url.inspect} "
        s << "transitions=#{@transitions.size}"
        s << '>'
    end

    private

    def fill_in_form_inputs( form, inputs = nil )
        form.find_elements( :css, 'input, textarea' ).each do |input|
            name_or_id = name_or_id_for( input )
            value      = inputs ? inputs[name_or_id] : value_for_name( name_or_id )

            begin
                input.clear
                input.send_keys( value.to_s.recode )
            # Disabled inputs and such...
            rescue Selenium::WebDriver::Error::WebDriverError => e
                print_debug_level_2 "Could not fill in form input '#{name_or_id}'" <<
                                        " because: #{e} [#{e.class}"
            end
        end

        form.find_elements( :tag_name, 'select' ).each do |select|
            name_or_id = name_or_id_for( select )
            value      = inputs ? inputs[name_or_id] : value_for_name( name_or_id )

            options = select.find_elements( tag_name: 'option' )
            options.each do |option|

                begin
                    if option[:value] == value || option.text == value
                        option.click
                        return
                    end
                # Disabled inputs and such...
                rescue Selenium::WebDriver::Error::WebDriverError => e
                    print_debug_level_2 "Could not fill in form select '#{name_or_id}'" <<
                                            " because: #{e} [#{e.class}"
                end
            end
        end
    end

    def skip_state?( state )
        self.skip_states.include? state
    end

    def skip_state( state )
        self.skip_states << state
    end

    def update_skip_states( states )
        self.skip_states.merge states
    end

    def name_or_id_for( element )
        name = element[:name].to_s
        return name if !name.empty?

        id = element[:id].to_s
        return id if !id.empty?

        nil
    end

    def with_timeout( timeout, &block )
        Timeout.timeout( timeout ) do
            block.call
        end
    #rescue
        #ap 'TIMEOUT'
        #ap caller
        #raise
    end

    # @param    [Watir::HTMLElement]    element
    # @return   [String]
    #   Value to use to fill-in the input.
    #
    # @see OptionGroups::Input.value_for_name
    def value_for( element )
        Options.input.value_for_name( name_or_id_for( element ) )
    end

    def value_for_name( name )
        Options.input.value_for_name( name )
    end

    def spawn_browser
        if !spawn_phantomjs
            fail Error::Spawn, 'Could not start the browser process.'
        end

        @browser_url
    end

    def spawn_phantomjs
        return @browser_url if @browser_url

        print_debug 'Spawning PhantomJS...'

        ChildProcess.posix_spawn = true

        port   = nil
        output = ''

        10.times do |i|
            # Clear output of previous attempt.
            output = ''
            done   = false
            port   = Utilities.available_port

            start_proxy

            print_debug_level_2 "Attempt ##{i}, chose port number #{port}"

            begin
                with_timeout BROWSER_SPAWN_TIMEOUT do
                    print_debug_level_2 "Spawning process: #{self.class.executable}"

                    r, w  = IO.pipe
                    ri, @kill_process = IO.pipe

                    @lifeline_pid = Processes::Manager.spawn(
                        :browser,
                        executable: self.class.executable,
                        without_arachni: true,
                        fork: false,
                        new_pgroup: true,
                        stdin: ri,
                        stdout: w,
                        stderr: w,
                        port: port,
                        proxy_url: @proxy.url
                    )

                    w.close
                    ri.close

                    print_debug_level_2 'Process spawned, waiting for WebDriver server...'

                    # Wait for PhantomJS to initialize.
                     while !output.include?( 'running on port' )
                         begin
                             output << r.readpartial( 8192 )
                         # EOF or something, take a breather before retrying.
                         rescue
                             sleep 0.05
                         end
                     end

                    @browser_pid = output.scan( /^PID: (\d+)/ ).flatten.first.to_i

                    print_debug_level_2 '...WebDriver server is up.'
                    done = true
                end
            rescue Timeout::Error
                print_debug 'Spawn timed-out.'
            end

            if !output.empty?
                print_debug_level_2 output
            end

            if done
                print_debug 'PhantomJS is ready.'
                break
            end

            print_debug_level_2 'Killing process.'

            # Kill everything.
            shutdown
        end

        # Something went really bad, the browser couldn't be spawned even
        # after our valiant efforts.
        #
        # Bail out for now and count on the BrowserCluster to retry to boot
        # another process ass needed.
        if !@lifeline_pid
            log_error 'Could not spawn browser process.'
            log_error output
            return
        end

        @browser_url = "http://127.0.0.1:#{port}"
    end

    def start_proxy
        print_debug 'Booting up...'

        print_debug_level_2 'Starting proxy...'
        @proxy = HTTP::ProxyServer.new(
            concurrency:      @options[:concurrency],
            address:          '127.0.0.1',
            request_handler:  proc do |request, response|
                exception_jail { request_handler( request, response ) }
            end,
            response_handler: proc do |request, response|
                exception_jail { response_handler( request, response ) }
            end
        )
        @proxy.start_async
        print_debug_level_2 "... started proxy at: #{@proxy.url}"
    end

    def start_webdriver
        print_debug_level_2 'Starting WebDriver...'
        @watir = ::Watir::Browser.new( selenium )
        print_debug_level_2 "... started WebDriver at: #{@browser_url}"

        print_debug '...boot-up completed.'
    end

    def store_pages?
        !!@options[:store_pages]
    end

    # Loads `page` without taking a snapshot, used for restoring  the root page
    # after manipulation.
    def restore( page )
        load page, take_snapshot: false
    end

    def capture_snapshot_with_sink( page )
        return if page.dom.data_flow_sinks.empty? &&
            page.dom.execution_flow_sinks.empty?

        notify_on_new_page_with_sink( page )

        return if !store_pages?
        @page_snapshots_with_sinks << page
    end

    def wait_for_pending_requests
        sleep 0.2

        t = Time.now
        last_connections = []
        while @proxy.has_pending_requests?
            connections = @proxy.active_connections

            if last_connections != connections
                print_debug_level_2 "Waiting for #{@proxy.pending_requests} requests to complete:"
                connections.each do |connection|
                    if connection.request
                        print_debug_level_2 " * #{connection.request.url}"
                    else
                        print_debug_level_2 ' * Still reading request data.'
                    end
                end
            end
            last_connections = connections

            sleep 0.1

            # If the browser sends incomplete data the connection will remain
            # open indefinitely.
            next if Time.now - t < Options.browser_cluster.job_timeout
            connections.each(&:close)
            break
        end
    end

    def load_cookies( url, cookies = {} )
        # First clears the browser's cookies and then tricks it into accepting
        # the system cookies for its cookie-jar.
        #
        # Well, it doesn't really clear the browser's cookie-jar, but that's
        # not necessary because whatever cookies the browser has have already
        # gotten into the system-wide cookiejar, and since we're passing
        # all applicable cookies to the browser the end result will be that
        # it'll have the wanted values.

        url = normalize_url( url )

        set_cookies = {}
        HTTP::Client.cookie_jar.for_url( url ).each do |cookie|
            cookie = cookie.dup
            set_cookies[cookie.name] = cookie
        end

        cookies.each do |name, value|
            if set_cookies[name]
                set_cookies[name] = set_cookies[name].dup

                # Don't forget this, otherwise the #to_set_cookie call will
                # return the original raw data.
                set_cookies[name].affected_input_name = name
                set_cookies[name].update( name => value )
            else
                set_cookies[name] = Cookie.new( url: url, inputs: { name => value } )
            end
        end

        return if set_cookies.empty? &&
            Arachni::Options.browser_cluster.local_storage.empty?

        set_cookie = set_cookies.values.map(&:to_set_cookie)
        print_debug_level_2 "Setting cookies: #{set_cookie}"

        body = ''
        if Arachni::Options.browser_cluster.local_storage.any?
            body = <<EOJS
                <script>
                    var data = #{Arachni::Options.browser_cluster.local_storage.to_json};

                    for( prop in data ) {
                        localStorage.setItem( prop, data[prop] );
                    }
                </script>
EOJS
        end

        @selenium.navigate.to preload( HTTP::Response.new(
            code:    200,
            url:     "#{url}/set-cookies-#{request_token}",
            body:    body,
            headers: {
                'Set-Cookie' => set_cookie
            }
        ))
    end

    # Makes sure we have at least 2 windows open so that we can switch to the
    # last available one in case there's some JS in the page that closes one.
    def ensure_open_window
        window_handles = @selenium.window_handles

        if window_handles.size == 0
            @javascript.run( 'window.open()' )
            @selenium.switch_to.window( @selenium.window_handles.last )
        else
            if window_handles.size > 1
                # Keep the first
                window_handles[1..-1].each do |handle|
                    @selenium.switch_to.window( handle )
                    @selenium.close
                end

                @selenium.switch_to.window( @selenium.window_handles.first )
            end

            @selenium.navigate.to 'about:blank'
        end

        @selenium.manage.window.resize_to( @width, @height )
    end

    # # Firefox driver, only used for debugging.
    # def firefox
    #     profile = Selenium::WebDriver::Firefox::Profile.new
    #     profile.proxy = Selenium::WebDriver::Proxy.new http: @proxy.address,
    #                                                    ssl: @proxy.address
    #     [:firefox, profile: profile]
    # end
    #
    # # Chrome driver, only used for debugging.
    # def chrome
    #     [ :chrome, switches: [ "--proxy-server=#{@proxy.address}" ] ]
    # end

    def capabilities
        Selenium::WebDriver::Remote::Capabilities.phantomjs(
            # Selenium tries to be helpful by including screenshots for errors
            # in the JSON response. That's not gonna fly in this use case as
            # parsing lots of massive JSON responses at the same time will
            # have a significant impact on performance.
            takes_screenshot: false,

            # Needs to include the string Webkit:
            #   https://github.com/ariya/phantomjs/issues/14198
            #
            # Default is:
            #   Mozilla/5.0 (Unknown; Linux x86_64) AppleWebKit/538.1 (KHTML, like Gecko) PhantomJS/2.1.1 Safari/538.1
            'phantomjs.page.settings.userAgent'                   =>
                USER_AGENT,
            'phantomjs.page.customHeaders.X-Arachni-Browser-Auth' =>
                auth_token,
            'phantomjs.page.settings.resourceTimeout'             =>
                Options.http.request_timeout,
            'phantomjs.page.settings.loadImages'                  =>
                !Options.browser_cluster.ignore_images
        )
    end

    def flush_request_transitions
        @request_transitions.dup
    ensure
        @request_transitions.clear
    end

    def request_token
        @request_token ||= generate_token
    end

    def auth_token
        @auth_token ||= generate_token.to_s
    end

    def request_handler( request, response )
        request.performer = self

        return if request.headers['X-Arachni-Browser-Auth'] != auth_token
        request.headers.delete 'X-Arachni-Browser-Auth'

        print_debug_level_2 "Request: #{request.url}"

        # We can't have 304 page responses in the framework, we need full request
        # and response data, the browser cache doesn't help us here.
        #
        # Still, it's a nice feature to have when requesting assets or anything
        # else.
        if request.url == @last_url
            request.headers.delete 'If-None-Match'
            request.headers.delete 'If-Modified-Since'
        end

        if @javascript.serve( request, response )
            print_debug_level_2 'Serving local JS.'
            return
        end

        if !request.url.include?( request_token )
            if ignore_request?( request )
                print_debug_level_2 'Out of scope, ignoring.'
                return
            end

            if @add_request_transitions
                synchronize do
                    @request_transitions << Page::DOM::Transition.new(
                        request.url, :request
                    )
                end
            end
        end

        # Signal the proxy to not actually perform the request if we have a
        # preloaded response for it.
        if from_preloads( request, response )
            print_debug_level_2 'Resource has been preloaded.'

            # There may be taints or custom JS code that need to be updated.
            javascript.inject response
            return
        end

        print_debug_level_2 'Request can proceed to origin.'

        # Capture the request as elements of pages -- let's us grab AJAX and
        # other browser requests and convert them into elements we can analyze
        # and audit.
        if request.scope.in?
            capture( request )
        end

        request.headers['user-agent'] = Options.http.user_agent

        # Signal the proxy to continue with its request to the origin server.
        true
    end

    def response_handler( request, response )
        return if request.url.include?( request_token )

        # Prevent PhantomJS from caching the root page, we need to have an
        # associated response.
        if @last_url == response.url
            response.headers.delete 'Cache-control'
            response.headers.delete 'Etag'
            response.headers.delete 'Date'
            response.headers.delete 'Last-Modified'
        end

        # Allow our own scripts to run.
        response.headers.delete 'Content-Security-Policy'

        print_debug_level_2 "Got response: #{response.url}"

        @request_transitions.each do |transition|
            next if !transition.running? || transition.element != request.url
            transition.complete
        end

        # If we abort the request because it's out of scope we need to emulate
        # an OK response because we **do** want to be able to grab a page with
        # the out of scope URL, even if it's empty.
        # For example, unvalidated_redirect checks need this.
        if response.code == 0
            if enforce_scope? && response.scope.out?
                response.code = 200
            end
        else
            if javascript.inject( response )
                print_debug_level_2 'Injected custom JS.'
            end
        end

        # Don't store assets, the browsers will cache them accordingly.
        if request_for_asset?( request ) || !response.text?
            print_debug_level_2 'Asset detected, will not store.'
            return
        end

        # No-matter the scope, don't store resources for external domains.
        if !response.scope.in_domain?
            print_debug_level_2 'Outside of domain scope, will not store.'
            return
        end

        if enforce_scope? && response.scope.out?
            print_debug_level_2 'Outside of general scope, will not store.'
            return
        end

        whitelist_asset_domains( response )
        save_response response

        print_debug_level_2 'Stored.'

        nil
    end

    def ignore_request?( request )
        print_debug_level_2 "Checking: #{request.url}"

        if !enforce_scope?
            print_debug_level_2 'Allow: Scope enforcement disabled.'
            return
        end

        if request_for_asset?( request )
            print_debug_level_2 'Allow: Asset detected.'
            return false
        end

        if !request.scope.follow_protocol?
            print_debug_level_2 'Disallow: Cannot follow protocol.'
            return true
        end

        if !request.scope.in_domain?
            if self.class.asset_domains.include?( request.parsed_url.domain )
                print_debug_level_2 'Allow: Out of scope but in CDN list.'
                return false
            end

            print_debug_level_2 'Disallow: Domain out of scope and not in CDN list.'
            return true
        end

        if request.scope.too_deep?
            print_debug_level_2 'Disallow: Too deep.'
            return true
        end

        if !request.scope.include?
            print_debug_level_2 'Disallow: Does not match inclusion rules.'
            return true
        end

        if request.scope.exclude?
            print_debug_level_2 'Disallow: Matches exclusion rules.'
            return true
        end

        if request.scope.redundant?
            print_debug_level_2 'Disallow: Matches redundant rules.'
            return true
        end

        false
    end

    def request_for_asset?( request )
        ASSET_EXTENSIONS.include?( request.parsed_url.resource_extension.to_s.downcase )
    end

    def whitelist_asset_domains( response )
        synchronize do
            @whitelist_asset_domains ||= Support::LookUp::HashSet.new
            return if @whitelist_asset_domains.include? response.body
            @whitelist_asset_domains << response.body

            ASSET_EXTRACTORS.each do |regexp|
                response.body.scan( regexp ).flatten.compact.each do |url|
                    next if !(domain = self.class.add_asset_domain( url ))

                    print_debug_level_2 "#{domain} from #{url} based on #{regexp.source}"
                end
            end
        end
    end

    def capture( request )
        return if !@last_url || !capture?

        elements = {
            forms: [],
            jsons: [],
            xmls:  []
        }

        found_element = false

        if (json = JSON.from_request( @last_url, request ))
            print_debug_level_2 "Extracted JSON input:\n#{json.source}"

            elements[:jsons] << json
            found_element = true
        end

        if !found_element && (xml = XML.from_request( @last_url, request ))
            print_debug_level_2 "Extracted XML input:\n#{xml.source}"

            elements[:xmls] << xml
            found_element = true
        end

        case request.method
            when :get
                inputs = request.parsed_url.query_parameters
                return if inputs.empty?

                elements[:forms] << Form.new(
                    url:    @last_url,
                    action: request.url,
                    method: request.method,
                    inputs: inputs
                )

            when :post
                inputs = request.parsed_url.query_parameters
                if inputs.any?
                    elements[:forms] << Form.new(
                        url:    @last_url,
                        action: request.url,
                        method: :get,
                        inputs: inputs
                    )
                end

                if !found_element && (inputs = request.body_parameters).any?
                    elements[:forms] << Form.new(
                        url:    @last_url,
                        action: request.url,
                        method: request.method,
                        inputs: inputs
                    )
                end

            else
                return
        end

        if (form = elements[:forms].last)
            print_debug_level_2 "Extracted form input:\n" <<
                "#{form.method.to_s.upcase} #{form.action} #{form.inputs}"
        end

        el = elements.values.flatten

        if el.empty?
            print_debug_level_2 'No elements found.'
            return
        end

        # Don't bother if the system in general has already seen the vectors.
        if el.empty? || !el.find { |e| !ElementFilter.include?( e ) }
            print_debug_level_2 'Ignoring, already seen.'
            return
        end

        begin
            if !el.find { |e| !skip_state?( e ) }
                print_debug_level_2 'Ignoring, already seen.'
                return
            end

            el.each { |e| skip_state e.id }
        # This could be an orphaned HTTP request, without a job, if running in
        # BrowserCluster::Worker.
        rescue NoMethodError
        end

        page = Page.from_data( elements.merge( url: request.url ) )
        page.response.request = request
        page.dom.push_transition Page::DOM::Transition.new( request.url, :request )

        @captured_pages << page if store_pages?
        notify_on_new_page( page )
    rescue => e
        print_debug "Could not capture: #{request.url}"
        print_debug request.body.to_s
        print_debug_exception e
    end

    def from_preloads( request, response )
        synchronize do
            return if !(preloaded = preloads.delete( request.url ))

            copy_response_data( preloaded, response )
            response.request = request
            save_response( response ) if !preloaded.url.include?( request_token )

            preloaded
        end
    end

    def copy_response_data( source, destination )
        [:code, :url, :body, :headers, :ip_address, :return_code,
         :return_message, :headers_string, :total_time, :time].each do |m|
            destination.send "#{m}=", source.send( m )
        end

        javascript.inject destination
        nil
    end

    def save_response( response )
        synchronize do
            notify_on_response response
            return response if !response.text?

            @window_responses[response.url] = response
        end
    end

    def get_response( url )
        synchronize do
            # Order is important, #normalize_url by can get confused and remove
            # everything after ';' by treating it as a path parameter.
            # Rightly so...but we need to bypass it when auditing LinkTemplate
            # elements.
            @window_responses[url] ||
                @window_responses[normalize_watir_url( url )] ||
                @window_responses[normalize_url( url )]
        end
    end

    def enforce_scope?
        !@ignore_scope
    end

    def normalize_watir_url( url )
        normalize_url( ::URI.encode( url, ';' ) ).gsub( '%3B', '%253B' )
    end

end
end
