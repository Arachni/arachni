=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'childprocess'
require 'watir-webdriver'
require_relative 'watir/element'
require_relative 'selenium/webdriver/remote/http/typhoeus'
require_relative 'processes/manager'
require_relative 'browser/element_locator'
require_relative 'browser/javascript'

module Arachni

# @note Depends on PhantomJS 1.9.2.
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
    PHANTOMJS_SPAWN_TIMEOUT = 4

    # How much time to wait for a targeted HTML element to appear on the page
    # after the page is loaded.
    ELEMENT_APPEARANCE_TIMEOUT = 5

    # Let the browser take as long as it needs to complete an operation.
    WATIR_COM_TIMEOUT = 3600 # 1 hour.

    HTML_IDENTIFIERS = ['<!doctype html', '<html', '<head', '<body', '<title', '<script']

    # @return   [Array<Page::DOM::Transition>]
    attr_reader :transitions

    # @return   [Hash]
    #   Preloaded resources, by URL.
    attr_reader :preloads

    # @return   [Watir::Browser]
    #   Watir driver interface.
    attr_reader :watir

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
    attr_reader :pid

    # @return   [Bool]
    #   `true` if a supported browser is in the OS PATH, `false` otherwise.
    def self.has_executable?
        !!executable
    end

    # @return   [String]
    #   Path to the PhantomJS executable.
    def self.executable
        Selenium::WebDriver::PhantomJS.path
    end

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

        @proxy = HTTP::ProxyServer.new(
            concurrency:      @options[:concurrency],
            address:          '127.0.0.1',
            request_handler:  proc do |request, response|
                synchronize { exception_jail { request_handler( request, response ) } }
            end,
            response_handler: proc do |request, response|
                synchronize { exception_jail { response_handler( request, response ) } }
            end
        )

        @options[:store_pages] = true if !@options.include?( :store_pages )

        @proxy.start_async

        @watir = ::Watir::Browser.new( selenium )

        # User-controlled response cache, by URL.
        @cache = Support::Cache::LeastRecentlyUsed.new( 200 )

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

        ensure_open_window
    end

    def clear_buffers
        synchronize do
            @preloads.clear
            @cache.clear
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

    # @param    [String, HTTP::Response, Page]  resource
    #   Loads the given resource in the browser. If it is a string it will be
    #   treated like a URL.
    #
    # @return   [Browser]
    #   `self`
    def load( resource, options = {} )
        @last_dom_url = nil

        case resource
            when String
                goto resource, options

            when HTTP::Response
                goto preload( resource ), options

            when Page
                HTTP::Client.update_cookies resource.cookie_jar

                @transitions = resource.dom.transitions.dup
                update_skip_states resource.dom.skip_states

                @last_dom_url = resource.dom.url

                @add_request_transitions = false if @transitions.any?
                resource.dom.restore self
                @add_request_transitions = true

            else
                fail Error::Load,
                     "Can't load resource of type #{resource.class}."
        end

        self
    end

    # @note The preloaded resource will be removed once used, for a persistent
    #   cache use {#cache}.
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
                                 "Can't load resource of type #{resource.class}."
                    end

        save_response( response ) if !response.url.include?( request_token )

        @preloads[response.url] = response
        response.url
    end

    # @param    [HTTP::Response, Page]  resource
    #   Cache a resource in order to be instantly available by URL via {#load}.
    def cache( resource = nil )
        return @cache if !resource

        response =  case resource
                        when HTTP::Response
                            resource

                        when Page
                            resource.response

                        else
                            fail Error::Load,
                                 "Can't load resource of type #{resource.class}."
                    end

        save_response response
        @cache[response.url] = response
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

        @last_url = url

        ensure_open_window

        load_cookies url, extra_cookies

        transition = Page::DOM::Transition.new( :page, :load,
            url:     url,
            cookies: extra_cookies
        ) do
            watir.goto url

            @javascript.wait_till_ready
            wait_for_timers

            wait_for_pending_requests

            javascript.set_element_ids
        end

        if @add_request_transitions
            @transitions << transition
        end

        @add_request_transitions = pre_add_request_transitions

        HTTP::Client.update_cookies cookies

        # Capture the page at its initial state.
        capture_snapshot if take_snapshot

        transition
    end

    def shutdown
        begin
            watir.close if browser_alive?
        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error
        end

        kill_process
        @proxy.shutdown
    end

    # @return   [String]
    #   Current URL.
    def url
        normalize_url watir.url
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
    # @param    [Bool]  mark_state
    #   Mark each element/events as visited and skip it if it has already been
    #   seen.
    #
    # @yield    [ElementLocator,Array<Symbol>]
    #   Hash with information about the element, its tag name, applicable events
    #   along with their handlers and attributes.
    def each_element_with_events( mark_state = true )
        current_url = url

        javascript.dom_elements_with_events.each do |element|
            tag_name   = element['tag_name']
            attributes = element['attributes']
            events     = element['events']

            case tag_name
                when 'a'
                    href = attributes['href'].to_s

                    if !href.empty?
                        if href.downcase.start_with?( 'javascript:' )
                            events << [ :click, href ]
                        else
                            next if skip_path?( to_absolute( href, current_url ) )
                        end
                    end

                when 'input'
                    if attributes['type'].to_s.downcase == 'image'
                        events << [ :click, 'image' ]
                    end

                when 'form'
                    action = attributes['action'].to_s

                    if !action.empty?
                        if action.downcase.start_with?( 'javascript:' )
                            events << [ :submit, action ]
                        else
                            next if skip_path?( to_absolute( action, current_url ) )
                        end
                    end
            end

            next if events.empty?

            if mark_state
                state = "#{tag_name}#{attributes}#{events}"
                next if skip_state?( state )
                skip_state state
            end

            yield ElementLocator.new( tag_name: tag_name, attributes: attributes ),
                    events
        end

        self
    end

    # @return   [String]
    #   Snapshot ID used to determine whether or not a page snapshot has already
    #   been seen. Uses both elements and their DOM events and possible audit
    #   workload to determine the ID, as page snapshots should be retained both
    #   when further browser analysis can be performed and when new element
    #   audit workload (but possibly without any DOM relevance) is available.
    def snapshot_id
        current_url = url

        id = []
        javascript.dom_elements_with_events.each do |element|
            tag_name   = element['tag_name']
            attributes = element['attributes']
            events     = element['events'] +
                Javascript.select_event_attributes( attributes ).to_a
            element_id = attributes['id'].to_s

            case tag_name
                when 'a'
                    href        = attributes['href'].to_s
                    element_id << href

                    if !href.empty?
                        if href.downcase.start_with?( 'javascript:' )
                            events << [ :click, href ]
                        else
                            absolute = to_absolute( href, current_url )
                            next if skip_path?( absolute )

                            events << [ :click, href ]
                        end
                    else
                        events << [ :click, current_url ]
                    end

                when 'input', 'textarea', 'select'
                    events     << [ tag_name.to_sym ]
                    element_id << attributes['name'].to_s

                when 'form'
                    action      = attributes['action'].to_s
                    element_id << "#{action}#{attributes['name']}"

                    if !action.empty?
                        if action.downcase.start_with?( 'javascript:' )
                            events << [ :submit, action ]
                        else
                            absolute = to_absolute( action, current_url )
                            if !skip_path?( absolute )
                                events << [ :submit, absolute ]
                            end
                        end
                    else
                        events << [ :submit, current_url ]
                    end
            end

            next if events.empty?

            id << "#{tag_name}:#{element_id}:#{events}"
        end

        id.uniq.sort.to_s
    end

    # Triggers all events on all elements (**once**) and captures
    # {#page_snapshots page snapshots}.
    #
    # @return   [Browser]
    #   `self`
    def trigger_events
        root_page = to_page

        each_element_with_events do |locator, events|
            events.each do |name, _|
                distribute_event( root_page, locator, name.to_sym )
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
    # @param    [Page]    page
    # @param    [ElementLocator]  locator
    # @param    [Symbol]  event
    def distribute_event( page, locator, event )
        trigger_event( page, locator, event )
    end

    # @note Captures page {#page_snapshots}.
    #
    # Triggers `event` on the element described by `tag` on `page`.
    #
    # @param    [Page]    page
    #   Page containing the element's `tag`.
    # @param    [ElementLocator]  element
    # @param    [Symbol]  event
    #   Event to trigger.
    def trigger_event( page, element, event )
        event = event.to_sym
        transition = fire_event( element, event )

        if !transition
            print_info "Could not trigger '#{event}' on '#{element}' because" <<
                ' the page has changed, capturing a new snapshot.'
            capture_snapshot

            print_info 'Restoring page.'
            restore page
            return
        end

        capture_snapshot( transition )
        restore page
    end

    # Triggers `event` on `element`.
    #
    # @param    [Watir::Element, ElementLocator]  element
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
                element = element.locate( self )
            rescue Selenium::WebDriver::Error::WebDriverError,
                Watir::Exception::Error => e

                print_debug "Element '#{element.inspect}' could not be " <<
                                "located for triggering '#{event}'."
                print_debug
                print_debug_exception e
                return
            end
        end

        # The page may need a bit to settle and the element is lazily located
        # by Watir so give it a few tries.
        begin
            with_timeout ELEMENT_APPEARANCE_TIMEOUT do
                sleep 0.1 while !element.exists?
            end
        rescue Timeout::Error
            print_debug_level_2 "#{element.inspect} did not appear in " <<
                                    "#{ELEMENT_APPEARANCE_TIMEOUT}."
            return
        end

        if !element.visible?
            print_debug_level_2 "#{element.inspect} is not visible, skipping..."
            return
        end

        if locator
            opening_tag = locator.to_s
            tag_name    = locator.tag_name
        else
            opening_tag = element.opening_tag
            tag_name    = element.tag_name
            locator     = ElementLocator.from_html( opening_tag )
        end

        print_debug_level_2 "#{__method__} [start]: #{event} (#{options}) #{locator}"

        tag_name = tag_name.to_sym

        notify_on_fire_event( element, event )

        tries = 0
        begin
            Page::DOM::Transition.new( locator, event, options ) do
                had_special_trigger = false

                if tag_name == :form
                    fill_in_form_inputs( element, options[:inputs] )

                    if event == :submit
                        element.to_subtype.submit
                        had_special_trigger = true
                    end
                elsif tag_name == :input && event == :click &&
                        element.attribute_value(:type) == 'image'

                    element.to_subtype.click
                    had_special_trigger = true

                elsif [:keyup, :keypress, :keydown, :change, :input, :focus, :blur, :select].include? event

                    # Some of these need an explicit event triggers.
                    had_special_trigger = true if ![:change, :blur, :focus, :select].include? event

                    element.send_keys( (options[:value] || value_for( element )).to_s )
                end

                element.fire_event( event ) if !had_special_trigger

                print_debug_level_2 "#{__method__} [waiting for requests]: #{event} (#{options}) #{locator}"
                wait_for_pending_requests
                print_debug_level_2 "#{__method__} [done waiting for requests]: #{event} (#{options}) #{locator}"

                # puts source_with_line_numbers
                print_debug_level_2 "#{__method__} [done]: #{event} (#{options}) #{locator}"
            end
        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error => e

            sleep 0.1

            tries += 1
            retry if tries < 5

            print_debug "Error when triggering event for: #{url}"
            print_debug "-- '#{event}' on: #{opening_tag}"
            print_debug
            print_debug_exception e

            nil
        end
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

    # @return   [Page]
    #   Converts the current browser window to a {Page page}.
    def to_page
        if !(r = response)
            return Page.from_data(
                dom: {
                    url: watir.url
                },
                response: {
                    code: 0,
                    url:  url
                }
            )
        end

        page                          = r.to_page
        page.body                     = source
        page.dom.url                  = watir.url
        page.dom.digest               = @javascript.dom_digest
        page.dom.execution_flow_sinks = @javascript.execution_flow_sinks
        page.dom.data_flow_sinks      = @javascript.data_flow_sinks
        page.dom.transitions          = @transitions.dup
        page.dom.skip_states          = skip_states.dup

        # Go through auditable DOM forms and cookies and remove the DOM from
        # them if no events are associated with it.
        #
        # This can save **A LOT** of time during the audit.
        if Options.audit.form_doms? && @javascript.supported?
            page.forms.each do |form|
                next if !form.node || !form.dom

                action = form.node['action'].to_s
                form.dom.browser = self

                next if action.downcase.start_with?( 'javascript:' ) ||
                    form.dom.locate.events.any?

                form.skip_dom = true
            end

            page.update_metadata
        end

        if Options.audit.cookie_doms? && @javascript.supported?
            sinks = @javascript.taint_tracer.data_flow_sinks
            page.cookies.each do |cookie|
                next if sinks.include?( cookie.name ) ||
                    sinks.include?( cookie.value )

                cookie.skip_dom = true
            end

            page.update_metadata
        end

        page
    end

    def capture_snapshot( transition = nil )
        pages = []

        request_transitions = flush_request_transitions
        transitions = ([transition] + request_transitions).flatten.compact

        begin
            # Skip about:blank windows.
            watir.windows( url: /^http/ ).each do |window|
                window.use do
                    next if !(page = to_page)

                    if pages.empty?
                        transitions.each do |t|
                            @transitions << t
                            page.dom.push_transition t
                        end
                    end

                    capture_snapshot_with_sink( page )

                    unique_id  = self.snapshot_id
                    next if skip_state? unique_id
                    skip_state unique_id

                    notify_on_new_page( page )

                    if store_pages?
                        @page_snapshots[unique_id.hash] = page
                        pages << page
                    end
                end
            end
        rescue => e
            print_debug "Could not capture snapshot for: #{@last_url}"

            if transition
                print_debug "-- #{transition}"
            end

            print_debug
            print_debug_exception e
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
    #   Browser cookies.
    def cookies
        js_cookies = begin
            # Watir doesn't tell us if cookies are HttpOnly, so we need to figure
            # this out ourselves, by checking for JS visibility.
            javascript.run( 'return document.cookie' )
        # We may not have a page.
        rescue Selenium::WebDriver::Error::WebDriverError
            ''
        end

        watir.cookies.to_a.map do |c|
            original_name = c[:name].to_s

            c[:path]     = '/' if c[:path] == '//'
            c[:name]     = Cookie.decode( c[:name].to_s )
            c[:value]    = Cookie.decode( c[:value].to_s )
            c[:httponly] = !js_cookies.include?( original_name )

            Cookie.new c.merge( url: @last_url || url )
        end
    end

    # @return   [String]
    #   HTML code of the evaluated (DOM/JS/AJAX) page.
    def source
        watir.html
    end

    def load_delay
        #(intervals + timeouts).map { |t| t[1] }.max
        @javascript.timeouts.compact.map { |t| t[1].to_i }.max
    end

    def wait_for_timers
        delay = load_delay
        return if !delay

        sleep [Options.http.request_timeout, delay].min / 1000.0
    end

    def skip_path?( path )
        enforce_scope? && super( path )
    end

    def response
        u = watir.url

        return if skip_path?( u )

        begin
            with_timeout Options.http.request_timeout / 1_000 do
                while !(r = get_response(u))
                    sleep 0.1
                end

                fail Timeout::Error if r.timed_out?

                return r
            end
        rescue Timeout::Error
            print_debug "Response for '#{u}' never arrived."
        end

        nil
    end

    # @return   [Selenium::WebDriver::Driver]
    #   Selenium driver interface.
    def selenium
        return @selenium if @selenium

        client = Selenium::WebDriver::Remote::Http::Typhoeus.new
        client.timeout = WATIR_COM_TIMEOUT

        @selenium = Selenium::WebDriver.for(
            :remote,

            # We need to spawn our own PhantomJS process because Selenium's
            # way sometimes gives us zombies.
            url:                  spawn_browser,
            desired_capabilities: capabilities,
            http_client:          client
        )
    end

    def inspect
        s = "#<#{self.class} "
        s << "pid=#{@pid} "
        s << "last-url=#{@last_url.inspect} "
        s << "transitions=#{@transitions.size}"
        s << '>'
    end

    private

    def fill_in_form_inputs( form, inputs = nil )
        form.text_fields.each do |input|
            name_or_id = name_or_id_for( input )
            value      = inputs ? inputs[name_or_id] : value_for( input )

            begin
                input.set( value.to_s.recode )
            # Disabled inputs and such...
            rescue Selenium::WebDriver::Error::WebDriverError,
                Watir::Exception::Error => e
                print_debug_level_2 "Could not fill in form input '#{name_or_id}'" <<
                                        " because: #{e} [#{e.class}"
            end
        end

        form.selects.each do |input|
            name_or_id = name_or_id_for( input )
            value      = inputs ? inputs[name_or_id] : value_for( input )

            begin
                input.select_value( value.to_s.recode )
            # Disabled inputs and such...
            rescue Selenium::WebDriver::Error::WebDriverError,
                Watir::Exception::Error => e
                print_debug_level_2 "Could not fill in form select '#{name_or_id}'" <<
                                        " because: #{e} [#{e.class}"
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
        name = element.attribute_value(:name).to_s
        return name if !name.empty?

        id = element.attribute_value(:id).to_s
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

        port = nil
        last_attempt_output = nil
        10.times do |i|
            done = false
            port = available_port

            print_debug "Attempt ##{i}, chose port number #{port}"

            begin
                with_timeout 10 do
                    print_debug "Spawning process: #{self.class.executable}"

                    @process = ChildProcess.build(
                        self.class.executable,
                        "--webdriver=#{port}",
                        "--proxy=http://#{@proxy.address}/",
                        '--ignore-ssl-errors=true',
                        '--disk-cache=true',
                        "--debug=#{!!debug?}"
                    )
                    # @process.leader = true
                    @process.detach = true

                    @process.io.stdout = Tempfile.new( 'phantomjs-out' )
                    @process.io.stderr = @process.io.stdout
                    @process.io.stderr.sync = @process.io.stdout.sync = true

                    @process.start
                    print_debug 'Process spawned, waiting for it to boot-up...'

                    File.open( @process.io.stdout.path, 'r' ) do |out|
                        buff = ''
                        # Wait for PhantomJS to initialize.
                         while !buff.include?( 'running on port' )
                             # It's silly to use #getc but it works consistently
                             # across MRI, Rubinius and JRuby.
                             buff << (out.getc rescue '').to_s
                         end

                        print_debug 'Boot-up complete.'
                        done = true
                    end
                end
            rescue Timeout::Error
                print_debug 'Spawn timed-out.'
            end

            if @process.io.stdout
                last_attempt_output = IO.read( @process.io.stdout )
                print_debug last_attempt_output
            end

            if done
                print_debug 'PhantomJS is ready.'
                break
            end

            print_debug 'Killing process.'
            kill_process
        end

        # Something went really bad, the browser couldn't be spawned even
        # after our valiant efforts.
        #
        # Bail out for now and count on the BrowserCluster to retry to boot
        # another process ass needed.
        if !@process
            log_error 'Could not spawn browser process.'
            log_error last_attempt_output
            return
        end

        begin
            @pid = @process.pid
        # Not supported on JRuby on MS Windows.
        rescue NotImplementedError
        end

        @browser_url = "http://127.0.0.1:#{port}"
    end

    def kill_process
        begin
            if @process && @process.alive?
                @process.stop
                @process.io.close rescue nil
            end
        rescue Errno::ECHILD
            false
        end

        @process     = nil
        @watir       = nil
        @selenium    = nil
        @pid         = nil
        @browser_url = nil
    end

    def browser_alive?
        @watir && @process && @process.alive?
    rescue Errno::ECHILD
        false
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
        # With AJAX requests being asynchronous and everything we need
        # to wait a split second to give the browser time to initialize
        # a connection.
        #
        # TODO: Add XMLHttpRequest.send() overrides to the DOMMonitor so
        # that we'll know for sure when to wait.
        sleep 0.1

        # Wait for pending requests to complete.
        #
        # The HTTP timeout option already guards us against this but I don't
        # fully trust the proxy so we're using #with_timeout as a fallback.
        with_timeout Options.http.request_timeout / 1_000 do
            sleep 0.1 while @proxy.has_connections?
        end

        true
    rescue Timeout::Error
        #ap 'PENDING REQUESTS TIMEOUT'
        #ap caller
        false
    end

    def load_cookies( url, cookies = {} )
        # First clears the browser's cookies and then tricks it into accepting
        # the system cookies for its cookie-jar.

        url = normalize_url( url )
        watir.cookies.clear

        set_cookies = {}
        HTTP::Client.cookie_jar.for_url( url ).each do |cookie|
            cookie = cookie.dup
            cookie.data.delete :domain
            set_cookies[cookie.name] = cookie
        end
        cookies.each do |name, value|
            if set_cookies[name]
                set_cookies[name] = set_cookies[name].dup
                set_cookies[name].update( name => value )
            else
                set_cookies[name] = Cookie.new( url: url, inputs: { name => value } )
            end
        end

        url = "#{url}/set-cookies-#{request_token}"
        watir.goto preload( HTTP::Response.new(
            url:     url,
            headers: {
                'Set-Cookie' => set_cookies.values.map(&:to_set_cookie)
            }
        ))
    end

    # Makes sure we have at least 2 windows open so that we can switch to the
    # last available one in case there's some JS in the page that closes one.
    def ensure_open_window
        return if watir.windows.size > 1

        watir.windows.last.use
        watir.window.resize_to( @width, @height )

        @javascript.run( 'window.open()' )
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
            'phantomjs.page.settings.userAgent'  => Options.http.user_agent,
            'phantomjs.page.customHeaders.X-Arachni-Browser-Auth' => auth_token,
            'phantomjs.page.settings.resourceTimeout' => Options.http.request_timeout,
            'phantomjs.page.settings.loadImages' => !Options.browser_cluster.ignore_images
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
        request.headers.delete( 'X-Arachni-Browser-Auth' )

        return if @javascript.serve( request, response )

        if !request.url.include?( request_token )
            return if ignore_request?( request )

            if @add_request_transitions
                @request_transitions << Page::DOM::Transition.new( request.url, :request )
            end
        end

        # Signal the proxy to not actually perform the request if we have a
        # preloaded or cached response for it.
        return if from_preloads( request, response ) || from_cache( request, response )

        begin
            # Capture the request as elements of pages -- let's us grab AJAX and
            # other browser requests and convert them into elements we can analyze
            # and audit.
            capture( request )
        rescue => e
            print_debug "Could not capture: #{request.url}"
            print_debug request.body.to_s
            print_debug_exception e
        end

        request.headers['user-agent'] = Options.http.user_agent

        # Signal the proxy to continue with its request to the origin server.
        true
    end

    def response_handler( request, response )
        return if request.url.include?( request_token )

        @request_transitions.each do |transition|
            next if !transition.running? || transition.element != request.url
            transition.complete
        end

        # No-matter the scope, don't store resources for external domains.
        return if !response.scope.in_domain?

        return if enforce_scope? && response.scope.out?

        intercept response
        save_response response

        nil
    end

    def intercept( response )
        return if !intercept?( response )
        @javascript.inject( response )
    end

    def intercept?( response )
        return false if response.body.empty?

        # We only care about HTML.
        return false if !response.headers.content_type.to_s.downcase.start_with?( 'text/html' )

        # Let's check that the response at least looks like it contains HTML
        # code of interest.
        body = response.body.downcase
        return false if !HTML_IDENTIFIERS.find { |tag| body.include? tag.downcase }

        # The last check isn't fool-proof, so don't do it when loading the page
        # for the first time, but only when the page loads stuff via AJAX and whatnot.
        #
        # Well, we can be pretty sure that the root page will be HTML anyways.
        return true if @last_url == response.url

        # Finally, verify that we're really working with markup (hopefully HTML)
        # and that the previous checks weren't just flukes matching some other
        # kind of document.
        #
        # For example, it may have been JSON with the wrong content-type that
        # includes HTML -- it happens.
        begin
            return false if Nokogiri::XML( response.body ).children.empty?
        rescue => e
            print_debug "Javascript injection failed for: #{response.url}"
            print_debug "\n#{response.body}"
            print_debug_exception e
            return false
        end

        true
    end

    def ignore_request?( request )
        return if !enforce_scope?

        # Only allow CSS and JS resources to be loaded from out-of-scope domains.
        !['css', 'js'].include?( request.parsed_url.resource_extension ) &&
            (request.scope.out? || request.scope.redundant?)
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
            elements[:jsons] << json
            found_element = true
        end

        if !found_element && (xml = XML.from_request( @last_url, request ))
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

        el = elements.values.flatten

        # Don't bother if the system in general has already seen the vectors.
        return if el.empty? || !el.find { |e| !ElementFilter.include?( e ) }

        begin
            return if !el.find { |e| !skip_state?( e ) }
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
    end

    def from_preloads( request, response )
        return if !(preloaded = preloads.delete( request.url ))

        copy_response_data( preloaded, response )
        response.request = request
        save_response( response ) if !preloaded.url.include?( request_token )

        preloaded
    end

    def from_cache( request, response )
        return if !@cache.include?( request.url )

        copy_response_data( @cache[request.url], response )
        response.request = request
        save_response response
    end

    def copy_response_data( source, destination )
        [:code, :url, :body, :headers, :ip_address, :return_code,
         :return_message, :headers_string, :total_time, :time].each do |m|
            destination.send "#{m}=", source.send( m )
        end

        intercept destination
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
