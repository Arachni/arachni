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

require 'watir-webdriver'
require_relative 'watir/element'

module Arachni

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Browser
    include Module::Output
    include Utilities

    # {Browser} error namespace.
    #
    # All {Browser} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error

        # Raised when a given resource can't be loaded.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class Load < Error
        end
    end

    # Events that apply to all elements.
    GLOBAL_EVENTS = [
        :onclick,
        :ondblclick,
        :onmousedown,
        :onmousemove,
        :onmouseout,
        :onmouseover,
        :onmouseup
    ]

    # Special events for each element.
    EVENTS_PER_ELEMENT = {
        body: [
            :onload
        ],

        form: [
            :onsubmit,
            :onreset
        ],

        # These need to be covered via Watir's API, #send_keys etc.
        input: [
            :onselect,
            :onchange,
            :onfocus,
            :onblur,
            :onkeydown,
            :onkeypress,
            :onkeyup
        ],

        # These need to be covered via Watir's API, #send_keys etc.
        textarea: [
            :onselect,
            :onchange,
            :onfocus,
            :onblur,
            :onkeydown,
            :onkeypress,
            :onkeyup
        ],

        select: [
            :onchange,
            :onfocus,
            :onblur
        ],

        button: [
            :onfocus,
            :onblur
        ],

        label: [
            :onfocus,
            :onblur
        ]
    }

    NO_EVENTS_FOR_ELEMENTS = Set.new([
        :base, :bdo, :br, :head, :html, :iframe, :meta, :param, :script, :style,
        :title, :link, :script
    ])

    JS_OVERRIDES =
        IO.read( "#{File.dirname( __FILE__ )}/browser/overrides.js" )

    # @return   [Hash]   Preloaded resources, by URL.
    attr_reader :preloads

    # @return   [Watir::Browser]   Watir driver interface.
    attr_reader :watir

    # @return   [Bool]
    #   `true` if `phantomjs` is in the OS PATH, `false` otherwise.
    def self.has_executable?
        return @has_executable if !@has_executable.nil?
        @has_executable = !!Selenium::WebDriver::PhantomJS.path
    end

    def self.events
        Browser::GLOBAL_EVENTS | Browser::EVENTS_PER_ELEMENT.values.flatten.uniq
    end

    # @param    [Hash]  options
    # @option   options [Integer] :timeout  (5)
    #   Max time to wait for the page to settle (for pending AJAX requests etc).
    # @option   options [Bool] :store_pages  (true)
    #   Whether to store pages in addition to just passing them to {#on_new_page}.
    def initialize( options = {} )
        @options      = options.dup
        @shared_token = @options[:shared_token] || Utilities.generate_token

        @proxy = HTTP::ProxyServer.new(
            request_handler:  proc do |request, response|
                synchronize { request_handler( request, response ) }
            end,
            response_handler: proc do |request, response|
                synchronize { response_handler( request, response ) }
            end
        )

        @options[:timeout]     ||= 5
        @options[:store_pages]   = true if !@options.include?( :store_pages )

        @proxy.start_async

        @watir = ::Watir::Browser.new( selenium )

        ensure_open_window

        # User-controlled response cache, by URL.
        @cache = Support::Cache::LeastRecentlyUsed.new( 200 )

        # User-controlled preloaded responses, by URL.
        @preloads = {}

        # Captured pages -- populated by #capture.
        @captured_pages = []

        # Snapshots of the working page resulting from firing of events and
        # clicking of JS links.
        @page_snapshots = {}

        # Captures HTTP::Response objects per URL.
        @responses = {}

        # Keeps track of resources which should be skipped -- like already fired
        # events and clicked links etc.
        @skip = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        @transitions = []
        @request_transitions = []
        @add_request_transitions = true

        @on_new_page_blocks = []
        @on_response_blocks = []

        # Last loaded URL.
        @last_url = nil
    end

    def on_new_page( &block )
        fail ArgumentError, 'Missing block.' if !block_given?
        @on_new_page_blocks << block
    end

    def on_response( &block )
        fail ArgumentError, 'Missing block.' if !block_given?
        @on_response_blocks << block
    end

    # @param    [String, HTTP::Response, Page]  resource
    #   Loads the given resource in the browser. If it is a string it will be
    #   treated like a URL.
    #
    # @return   [Browser]   `self`
    def load( resource, take_snapshot = true )
        case resource
            when String
                goto resource, take_snapshot

            when HTTP::Response
                goto preload( resource ), take_snapshot

            when Page
                HTTP::Client.update_cookies resource.cookiejar

                @transitions = resource.dom.transitions.dup

                @add_request_transitions = false if @transitions.any?

                goto preload( resource ), take_snapshot
                replay_transitions

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

    # @param    [String]  url Loads the given URL in the browser.
    #
    # @return   [Browser]   `self`
    def goto( url, take_snapshot = true )
        @last_url = url = normalize_url( url )

        ensure_open_window

        load_cookies url

        watir.goto url

        wait_for_overrides
        wait_for_timers
        wait_for_pending_requests

        HTTP::Client.update_cookies cookies

        if @add_request_transitions
            @transitions << { page: :load }
        end

        # Capture the page at its initial state.
        capture_snapshot if take_snapshot

        self
    end

    def close_windows
        watir.cookies.clear
        clear_responses

        watir.execute_script( 'window.open()' )
        watir.windows.last.use

        watir.windows[0...-1].each { |w| w.close rescue nil }
    end

    def shutdown
        watir.close
        @proxy.shutdown
    end

    # @return   [String]    Current URL.
    def url
        normalize_url watir.url
    end

    # Explores the browser's DOM tree and captures page snapshots for each
    # state change until there are no more available.
    #
    # @param    [Hash]      strategy
    #   Strategy to use for traversal and retrieval of pages:
    # @option  strategy :depth  [Integer]   (nil)
    #   How deep to go into the DOM tree.
    # @option  strategy :exploration  [Symbol]
    #   Exploration strategy, available options are:
    #
    #   * {#explore} (Default)
    #   * {#trigger_events}
    #
    # @option  strategy :retrieval  [Symbol]
    #   Page retrieval strategy, available options are:
    #
    #   * {#flush_pages} (Default)
    #   * {#captured_pages}
    #   * {#page_snapshots}
    def explore_deep_and_flush( strategy = { } )
        strategy = {
            depth:       nil,
            exploration: :explore
        }.merge( strategy )

        pages = [ to_page ]

        done  = false
        depth = 0

        while !done do
            bcnt = pages.size
            pages |= pages.map do |p|
                load( p ).send( strategy[:exploration] ).flush_pages
            end.flatten

            if pages.size == bcnt || (strategy[:depth] && strategy[:depth] >= depth)
                done = true
                break
            end

            depth += 1
        end

        pages
    end

    # {#trigger_events Triggers events} on the current page's DOM depth.
    #
    # @return   [Browser]   `self`
    #
    # @see #trigger_events
    def explore
        trigger_events
        self
    end

    def skip?( action )
        @skip.include? action
    end

    def skip( action )
        @skip << action
    end

    # Triggers all events on all elements (**once**) and captures
    # {#page_snapshots page snapshots}.
    #
    # @return   [Browser]   `self`
    def trigger_events
        # Filter out irrelevant stuff first because the manipulation that comes
        # next is expensive, so let's not waste our time with them at all.
        pending = Set.new
        tries   = 0

        watir.elements.each.with_index do |element, i|
            begin
                tag_name    = element.tag_name
                opening_tag = element.opening_tag
                events      = element.events
            rescue => e
                tries += 1
                next if tries > 5

                print_info "Refreshing page cache because: #{e}"
                retry
            end

            case tag_name
                when 'a'
                    href = element.attribute_value( :href )
                    events << [ :click, href ] if href.start_with?( 'javascript:' )

                when 'form'
                    action = element.attribute_value( :action )
                    events << [ :submit, action ] if action.start_with?( 'javascript:' )
            end

            next if skip?( opening_tag ) ||
                NO_EVENTS_FOR_ELEMENTS.include?( tag_name.to_sym ) ||
                events.empty?

            skip opening_tag
            pending << { index: i, tag_name: tag_name, events: events }
        end

        root_page = to_page

        while (info = pending.shift) do
            info[:events].each do |name, _|
                distribute_event( root_page, info[:index], name.to_sym )
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
    # @param    [Page]  page
    # @param    [Integer]  element_index
    # @param    [Symbol]  event
    def distribute_event( page, element_index, event )
        trigger_event( page, element_index, event )
    end

    # Triggers `event` on the element at `element_index` on `page`.
    #
    # @param    [Page]  page
    # @param    [Integer]  element_index
    # @param    [Symbol]  event
    def trigger_event( page, element_index, event )
        event       = event.to_sym
        element     = watir.elements[element_index]
        opening_tag = element.opening_tag

        if !fire_event( element, event )
            restore page
            return
        end

        capture_snapshot( opening_tag => event.to_sym ).each do |snapshot|
            print_debug "Found new page variation by triggering '#{event}' on: #{opening_tag}"

            print_debug 'Page transitions:'
            snapshot.dom.transitions.each do |t|
                el, ev = t.first.to_a
                print_debug "-- '#{ev}' on: #{el}"
            end
        end

        restore page
    end

    # Triggers `event` on `element`.
    #
    # @param    [Watir::Element]  element
    # @param    [Symbol]  event
    #
    # @return   [Bool]
    #   `true` if the event was fired successfully, `false` otherwise.
    def fire_event( element, event )
        event       = event.to_sym
        opening_tag = element.opening_tag
        tag_name    = element.tag_name

        tries = 0
        begin
            if tag_name == 'form' && event == :submit
                element.submit
            elsif [:keyup, :keypress, :keydown].include? event
                element.send_keys 'Sample text'
            else
                element.fire_event( event )
            end

            wait_for_pending_requests

            true
        rescue Selenium::WebDriver::Error::UnknownError,
            Watir::Exception::UnknownObjectException => e

            tries += 1
            retry if tries < 5

            print_error "Error when triggering event for: #{url}"
            print_error "-- '#{event}' on: #{opening_tag}"
            print_error
            print_error
            print_error e
            print_error_backtrace e

            print_info 'Restoring page and aborting.'
            false
        end
    end

    # Starts capturing requests and parses them into elements of pages,
    # accessible via {#captured_pages}.
    #
    # @return   [Browser]   `self`
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
    # @return   [Browser]   `self`
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

    # @return   [Page]  Converts the current browser window to a {Page page}.
    def to_page
        page                 = response.deep_clone.to_page
        page.body            = source.dup
        page.cookies        |= cookies.dup
        page.dom.transitions = @transitions.dup

        page
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

    # @return   [Array<Cookie>]   Browser cookies.
    def cookies
        watir.cookies.to_a.map do |c|
            c[:path]  = '/' if c[:path] == '//'
            c[:name]  = Cookie.decode( c[:name].to_s )
            c[:value] = Cookie.decode( c[:value].to_s )

            Cookie.new c.merge( url: url )
        end
    end

    # @return   [String]   HTML code of the evaluated (DOM/JS/AJAX) page.
    def source
        watir.html
    end

    def timeouts
        return [] if !has_js_overrides?
        watir.execute_script "return _#{js_token}_setTimeouts;"
    end

    def intervals
        return [] if !has_js_overrides?
        watir.execute_script "return _#{js_token}_setIntervals;"
    end

    def html?
        response.headers.content_type.to_s.start_with? 'text/html'
    end

    def load_delay
        #(intervals + timeouts).map { |t| t.last }.max
        timeouts.map { |t| t.last }.max
    end

    def wait_for_timers
        delay = load_delay
        return if !delay
        sleep delay / 1000.0
    end

    def response
        get_response url
    end

    # @return   [Selenium::WebDriver::Driver]   Selenium driver interface.
    def selenium
        @selenum ||= Selenium::WebDriver.for( :phantomjs, desired_capabilities: capabilities )
    end

    def self.info
        { name: 'Browser' }
    end

    private

    def has_js_overrides?
        response.body.include?( js_token )
    end

    def wait_for_overrides
        return if !has_js_overrides?

        loop do
            begin
                if watir.execute_script( "return _#{js_token}_initialized"  ) == true
                    break
                end
            rescue
            end

            sleep 0.1
        end
    end

    def store_pages?
        !!@options[:store_pages]
    end

    def call_on_new_page_blocks( page )
        @on_new_page_blocks.each { |b| b.call page }
    end

    def call_on_response_blocks( page )
        @on_response_blocks.each { |b| b.call page }
    end

    # Loads `page` without taking a snapshot, used for restoring  the root page
    # after manipulation.
    def restore( page )
        load page, false
    end

    def replay_transitions
        @transitions.each do |transition|
            element, event = transition.to_a.first
            next if [:request, :load].include? event

            tag = element.match( /<(\w+)\b/ )[1]
            attributes = Nokogiri::HTML( element ).css( tag ).first.attributes.
                inject({}) { |h, (k, v)| h[k.gsub( '-' ,'_' ).to_sym] = v.to_s; h }

            # Not supported by Watir.
            attributes.delete( :cellpadding )
            attributes.delete( :cellspacing )

            begin

                # Try to find the relevant element but skip the transition if
                # it's no longer available.
                element = nil
                begin
                    element = watir.send( "#{tag}s", attributes ).first
                rescue Selenium::WebDriver::Error::UnknownError
                    next
                end

                fire_event element, event
            rescue => e
                print_error "Error when replying transition for: #{url}"
                @transitions.each do |t|
                    el, ev = t.to_a.first
                    print_error "-#{t == transition ? '>' : '-'} '#{ev}' on: #{el}"
                end

                print_error
                print_error "    #{tag} => #{attributes}"
                print_error
                print_error e
                print_error_backtrace e
            end
        end

        wait_for_pending_requests
    end

    def capture_snapshot( transition = nil )
        pages = []

        request_transitions = flush_request_transitions
        transitions = ([transition] + request_transitions).flatten.compact

        # Skip about:blank windows.
        watir.windows( url: /^http/ ).each do |window|
            window.use do
                page = to_page

                unique_id = "#{page.dom.hash}:#{cookies.map(&:name).sort}"
                next if skip? unique_id
                skip unique_id

                if pages.empty?
                    transitions.each do |t|
                        @transitions << t
                        page.dom.push_transition t
                    end
                end

                call_on_new_page_blocks( page )
                @page_snapshots[unique_id] = page if store_pages?
                pages << page
            end
        end

        pages
    end

    def wait_for_pending_requests
        # Wait for pending requests to complete.
        Timeout.timeout( @options[:timeout] ) do
            sleep 0.1 while @proxy.has_connections?
        end

        true
    rescue Timeout::Error
        false
    end

    def load_cookies( url )
        # First clears the browser's cookies and then tricks it into accepting
        # the system cookies for its cookie-jar.

        watir.cookies.clear

        url = "#{url}/set-cookies-#{request_token}"
        watir.goto preload( HTTP::Response.new(
            url:     url,
            headers: {
                'Set-Cookie' => HTTP::Client.cookie_jar.for_url( url ).
                    map( &:to_set_cookie )
            }
        ))
    end

    def request_token
        @request_token ||= generate_token
    end

    # Makes sure we have at least 2 windows open so that we can switch to the
    # last available one in case there's some JS in the page that closes one.
    def ensure_open_window
        return if watir.windows.size > 1

        watir.windows.last.use
        watir.execute_script( 'window.open()' )
    end

    def capabilities
        Selenium::WebDriver::Remote::Capabilities.phantomjs(
            'phantomjs.page.settings.userAgent'  => Options.user_agent,
            #'phantomjs.page.settings.loadImages' => false,
            'phantomjs.cli.args'                 => [
                "--proxy=http://#{@proxy.address}/",
                '--ignore-ssl-errors=true'
            ]
        )
    end

    def events_for( tag_name )
        tag_name = tag_name.to_sym
        return [] if NO_EVENTS_FOR_ELEMENTS.include?( tag_name )

        (EVENTS_PER_ELEMENT[tag_name] || []) + GLOBAL_EVENTS
    end

    def flush_request_transitions
        @request_transitions.dup
    ensure
        @request_transitions.clear
    end

    def request_handler( request, response )
        return if ignore_request?( request )

        if !request.url.include?( request_token ) && @add_request_transitions
            @request_transitions << { request.url => :request }
        end

        # Signal the proxy to not actually perform the request if we have a
        # preloaded or cached response for it.
        return if from_preloads( request, response ) || from_cache( request, response )

        # Capture the request as elements of pages -- let's us grab AJAX and
        # other browser requests and convert them into system elements we can
        # analyze and audit.
        capture( request )

        request.headers['user-agent'] = Options.user_agent

        # Signal the proxy to continue with its request to the origin server.
        true
    end

    def response_handler( request, response )
        return if request.url.include?( request_token )
        return if ignore_request?( request )

        intercept response
        save_response response
    end

    def intercept( response )
        return if !response.headers.content_type.to_s.start_with?( 'text/html' )
        return if response.body.include? js_token

        response.body = "\n<script>#{js_overrides}</script>\n#{response.body}"

        response.headers['content-length'] = response.body.size
    end

    def js_overrides
        @js_overrides ||= JS_OVERRIDES.gsub( '_token_', "_#{js_token}_" )
    end

    def js_token
        @shared_token
    end

    def ignore_request?( request )
        # Only allow CSS and JS resources to be loaded from out-of-scope domains.
        !['css', 'js'].include?( request.parsed_url.resource_extension ) &&
            skip_path?( request.url )
    end

    def capture( request )
        return if !capture?

        page = Page.from_data( url: @last_url )
        page.response.request = request
        page.dom.push_transition request.url => :request

        case request.method
            when :get
                inputs = parse_url_vars( request.url )
                return if inputs.empty?

                page.forms << Form.new(
                    url:    @last_url,
                    action: request.url,
                    method: request.method,
                    inputs: inputs
                ).tap(&:override_instance_scope)
                page.forms.uniq!

            when :post
                inputs = form_parse_request_body( request.body )
                return if inputs.empty?

                page.forms << Form.new(
                    url:    @last_url,
                    action: request.url,
                    method: request.method,
                    inputs: inputs
                ).tap(&:override_instance_scope)
                page.forms.uniq!
        end

        @captured_pages << page if store_pages?
        call_on_new_page_blocks( page )
    end

    def from_preloads( request, response )
        return if !(preloaded = preloads.delete( request.url ))

        copy_response_data( preloaded, response )
        response.request = request
        save_response( response ) if !preloaded.url.include?( request_token )

        preloaded
    end

    def from_cache( request, response )
        return if !(cached = @cache[request.url])

        copy_response_data( cached, response )
        response.request = request
        save_response response
    end

    def copy_response_data( source, destination )
        [:code, :url, :body, :headers, :ip_address, :return_code,
         :return_message, :headers_string, :total_time, :time,
         :version].each do |m|
            destination.send "#{m}=", source.send( m )
        end

        intercept destination
        nil
    end

    def clear_responses
        synchronize { @responses.clear }
    end

    def save_response( response )
        call_on_response_blocks response
        @responses[response.url] = response
    end

    def get_response( url )
        synchronize { @responses[url] }
    end

    def synchronize( &block )
        (@mutex ||= Mutex.new).synchronize( &block )
    end


end
end
