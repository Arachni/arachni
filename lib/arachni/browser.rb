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
    include UI::Output
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

    EVENT_ATTRIBUTES = [
        'onload',
        'onunload',
        'onblur',
        'onchange',
        'onfocus',
        'onreset',
        'onselect',
        'onsubmit',
        'onabort',
        'onkeydown',
        'onkeypress',
        'onkeyup',
        'onclick',
        'ondblclick',
        'onmousedown',
        'onmousemove',
        'onmouseout',
        'onmouseover',
        'onmouseup'
    ]

    # @return   [Hash]   Preloaded resources, by URL.
    attr_reader :preloads

    # @return   [Watir::Browser]   Watir driver interface.
    attr_reader :watir

    # @param    [Hash]  options
    # @option   options [Integer] :timeout  (5)
    #   Max time to wait for the page to settle (for pending AJAX requests etc).
    def initialize( options = {} )
        @options = options.dup

        @proxy = HTTP::ProxyServer.new(
            request_handler:  method( :request_handler ),
            response_handler: method( :response_handler )
        )

        @options[:timeout] ||= 5

        @proxy.start_async if !@proxy.running?

        @watir = ::Watir::Browser.new(
            Selenium::WebDriver.for( :phantomjs,
                desired_capabilities: Selenium::WebDriver::Remote::Capabilities.
                                          phantomjs( phantomjs_options ),
                args: "--proxy=http://#{@proxy.address}/ --ignore-ssl-errors=true"
            )
        )

        ensure_open_window

        # User-controlled response cache, by URL.
        @cache = Support::Cache::LeastRecentlyUsed.new( 200 )

        # User-controlled preloaded responses, by URL.
        @preloads = {}

        # Captured pages, by URL -- populated by #capture.
        @captured_pages = {}

        # Snapshots of the working page resulting from firing of events and
        # clicking of JS links.
        @page_snapshots = {}

        # Keeps track of resources which should be skipped -- like already fired
        # events and clicked links etc.
        @skip = Support::LookUp::HashSet.new

        @transitions = []
        @add_request_transitions = true
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
                @transitions = resource.transitions.dup

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
                            resource.response.deep_clone

                        else
                            fail Error::Load,
                                 "Can't load resource of type #{resource.class}."
                    end

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

        @cache[response.url] = response
        response.url
    end

    # @param    [String]  url Loads the given URL in the browser.
    #
    # @return   [Browser]   `self`
    def goto( url, take_snapshot = true )
        ensure_open_window

        @root_page_response = nil

        load_cookies url

        watir.goto @url = normalize_url( url )
        wait_for_pending_requests

        HTTP::Client.update_cookies cookies

        if @add_request_transitions
            @transitions << { page: :load }
        end

        # Capture the page at its initial state.
        capture_snapshot if take_snapshot

        self
    end

    def close
        watir.cookies.clear
        watir.close
        @proxy.shutdown
    end

    # @return   [String]    Current URL.
    def url
        @url || @root_page_response.url
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
    #   * {#visit_links}
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

    # {#trigger_events Triggers events} and
    # {#visit_links visits javascript links} on the current page's DOM depth.
    #
    # @return   [Browser]   `self`
    #
    # @see #trigger_events
    # @see #visit_links
    def explore
        trigger_events
        visit_links
        self
    end

    # Triggers all events on all elements (**once**) and captures
    # {#page_snapshots page snapshots}.
    #
    # @return   [Browser]   `self`
    def trigger_events
        pending = Set.new

        #ap 1
        #puts source

        watir.elements.each_with_index do |element, i|
            events = element.attributes & EVENT_ATTRIBUTES
            next if events.empty?

            html = element.html
            next if @skip.include? html

            @skip   << html
            pending << [i, events]
        end

        return self if pending.empty?

        root_page = to_page

        #puts source
        #ap '-' * 80

        while (tuple = pending.shift) do
            #puts source

            element_idx, events = *tuple
            element = watir.elements[element_idx]
            opening_tag = element.opening_tag
            #ap events

            events.each do |event|
                element.fire_event( event ) rescue nil
                wait_for_pending_requests

                @transitions << { opening_tag => event.to_sym }
                capture_snapshot

                #puts source

                restore root_page
            end

            restore root_page
        end

        self
    end

    # Visits javascript links **once** and captures
    # {#page_snapshots page snapshots}.
    #
    # @return   [Browser]   `self`
    def visit_links
        pending = Set.new

        watir.links.each do |a|
            href = a.href.to_s

            next if @skip.include?( href ) ||
                !href.start_with?( 'javascript:' ) ||
                href =~ /javascript:\s*void\(/

            @skip   << href
            pending << href.gsub( '%20', ' ' )
        end

        return self if pending.empty?

        root_page = to_page

        #puts source
        #ap '-' * 80

        while (href = pending.shift) do
            element = watir.link( href: href )

            @transitions << { element.opening_tag => :click }

            exception_jail( false ) { element.click }
            wait_for_pending_requests

            #puts source

            capture_snapshot
            restore root_page
        end

        self
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
        @captured_pages.values
    end

    # @return   [Page]  Converts the current browser window to a {Page page}.
    def to_page
        return if !@root_page_response

        current_response = @root_page_response.deep_clone

        page               = current_response.to_page
        page.response.body ||= source.dup
        page.dom_body      = source.dup
        page.cookies      |= cookies.dup
        page.transitions   = @transitions.dup

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
        captured_pages | page_snapshots
    ensure
        @captured_pages.clear
        @page_snapshots.clear
    end

    # @return   [Array<Cookie>]   Browser cookies.
    def cookies
        watir.cookies.to_a.map do |c|
            c[:path] = '/' if c[:path] == '//'
            Cookie.new c.merge( url: url )
        end
    end

    # @return   [String]   HTML code of the evaluated (DOM/JS/AJAX) page.
    def source
        watir.html
    end

    # @return   [Selenium::WebDriver::Driver]   Selenium driver interface.
    def selenium
        watir.driver
    end

    private

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
                inject({}) { |h, (k, v)| h[k.to_sym] = v.to_s; h }

            element = watir.send( "#{tag}s", attributes ).first
            element.fire_event( event )

            wait_for_pending_requests
        end
    end

    def capture_snapshot
        page = to_page
        hash = page.hash
        return if @skip.include? hash

        #ap page.transitions
        #puts page.dom_body

        @page_snapshots[hash] = page

        @skip << hash
    rescue => e
        print_error e
        print_error_backtrace e
    end

    def wait_for_pending_requests
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

    def phantomjs_options
        {
            'phantomjs.page.settings.userAgent'  => Options.user_agent,
            #'phantomjs.page.settings.loadImages' => false
        }
    end

    def request_handler( request, response )
        if !request.url.include?( request_token ) && @add_request_transitions
            @transitions << { request.url => :request }
        end

        # Signal the proxy to not actually perform the request if we have a
        # preloaded or cached response for it.
        return if from_preloads( request, response ) || from_cache( request, response )

        # Capture the request as elements of pages -- let's us grab AJAX and
        # other browser requests and convert them into system elements we can
        # analyze and audit.
        capture( request )

        # Signal the proxy to continue with its request to the origin server.
        true
    end

    def response_handler( request, response )
        return if request.url.include?( request_token )
        #@current_response = response
        @root_page_response ||= response
    end

    def capture( request )
        return if !capture?

        if !@captured_pages.include? url
            page = Page.from_data( url: url )
            page.response.request = request
            @captured_pages[url] = page
        end

        page = @captured_pages[url]
        page.push_transition request.url => :request

        case request.method
            when :get
                inputs = parse_url_vars( request.url )
                return if inputs.empty?

                page.forms << Form.new(
                    url:    url,
                    action: request.url,
                    method: request.method,
                    inputs: inputs
                ).tap(&:override_instance_scope)
                page.forms.uniq!

            when :post
                inputs = form_parse_request_body( request.body )
                return if inputs.empty?

                page.forms << Form.new(
                    url:    url,
                    action: request.url,
                    method: request.method,
                    inputs: inputs
                ).tap(&:override_instance_scope)
                page.forms.uniq!
        end

    end

    def from_preloads( request, response )
        return if !(preloaded = preloads.delete( request.url ))

        copy_response_data( preloaded, response )

        if !preloaded.url.include?( request_token )
            @root_page_response ||= preloaded
        end

        preloaded
    end

    def from_cache( request, response )
        return if !(cached = @cache[request.url])

        copy_response_data( cached, response )
        @root_page_response ||= cached
    end

    def copy_response_data( source, destination )
        [:code, :url, :body, :headers, :ip_address, :return_code,
         :return_message, :headers_string, :total_time, :time,
         :version].each do |m|
            destination.send "#{m}=", source.send( m )
        end
        nil
    end

end
end
