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

module Arachni

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Browser

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

    def initialize
        @proxy = HTTP::ProxyServer.new( request_handler: method( :request_handler ) )
        @proxy.start_async

        @watir = ::Watir::Browser.new(
            Selenium::WebDriver.for( :phantomjs,
                desired_capabilities: Selenium::WebDriver::Remote::Capabilities.
                                          phantomjs( phantomjs_options ),
                args: "--proxy=http://#{@proxy.address}/ --ignore-ssl-errors=true"
            )
        )

        # Captured pages, by URL.
        @pages    = {}

        # Response cache, by URL.
        @cache    = {}

        # Preloaded responses, by URL.
        @preloads = {}

        @current_response = nil
    end

    def close
        watir.cookies.clear
        watir.close
        @proxy.shutdown
    end

    # @return   [String]    Current URL.
    def url
        @url || @current_response.url
    end

    # @return   [Page]  Converts the current browser window to a {Page page}.
    def to_page
        return if !@current_response
        @current_response.body = source

        page = @current_response.to_page
        page.cookies |= cookies
        page
    end

    # Triggers all events on all page elements and also clicks anchors with
    # hrefs containing JavaScript ('javascript:').
    def trigger_events
        watir.elements.each do |element|
            EVENT_ATTRIBUTES.each do |event|
                # Not all elements support all events so rescue exceptions and
                # move on.
                element.fire_event( event ) rescue nil
            end
        end

        watir.as.each do |a|
            next if !a.href.to_s.start_with?( 'javascript:' )
            a.click
        end

        nil
    end

    # @param    [String, HTTP::Response, Page]  resource
    #   Loads the given resource in the browser. If it is a string it will be
    #   treated like a URL.
    def load( resource )
        case resource
            when String
                goto resource

            when HTTP::Response, Page
                goto preload( resource )

            else
                fail Error::Load,
                     "Can't load resource of type #{resource.class}."
        end

        nil
    end

    # @param    [String]  url Loads the given URL in the browser.
    def goto( url )
        load_cookies url
        watir.goto @url = url
        HTTP::Client.update_cookies cookies
        nil
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

    # Starts capturing requests and parsing them into elements of pages,
    # accessible via {#flush_pages}.
    #
    # @see #stop_capture
    # @see #capture?
    # @see #flush_pages
    def start_capture
        @capture = true
    end

    # Stops the page capture.
    #
    # @see #start_capture
    # @see #capture?
    # @see #flush_pages
    def stop_capture
        @capture = false
    end

    # @return   [Bool]
    #   `true` if the page capture is enabled, `false` otherwise.
    #
    # @see #start_capture
    # @see #stop_capture
    def capture?
        !!@capture
    end

    # @return   [Array<Page>]   Flushes the buffer of recorded pages.
    #
    # @see #start_capture
    # @see #stop_capture
    # @see #capture?
    def flush_pages
        @pages.values
    ensure
        @pages.clear
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

    def load_cookies( url )
        # First clears the browser's cookies and then tricks it into accepting
        # the system cookies for its cookie-jar.

        watir.cookies.clear

        url = "#{url}/set-cookies-#{Utilities.generate_token}"
        watir.goto preload( HTTP::Response.new(
            url:     url,
            headers: {
                'Set-Cookie' => HTTP::Client.cookie_jar.for_url( url ).
                    map( &:to_set_cookie )
            }
        ))
    end

    def phantomjs_options
        {
            'phantomjs.page.settings.userAgent'  => Options.user_agent,
            'phantomjs.page.settings.loadImages' => false
        }
    end

    def request_handler( request, response )
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

    def capture( request )
        return if !capture?

        if !@pages.include? url
            page = Page.from_data( url: url )
            page.response.request = request
            @pages[url] = page
        end

        page = @pages[url]

        case request.method
            when :get
                page.forms << Form.new(
                    url:    url,
                    action: request.url,
                    method: request.method,
                    inputs: Utilities.parse_url_vars( request.url )
                ).tap(&:override_instance_scope)

            when :post
                page.forms << Form.new(
                    url:    url,
                    action: request.url,
                    method: request.method,
                    inputs: Utilities.form_parse_request_body( request.body )
                ).tap(&:override_instance_scope)
        end

        page.forms.uniq!
    end

    def from_preloads( request, response )
        return if !(preloaded = preloads.delete( request.url ))

        copy_response_data( preloaded, response )
        @current_response = preloaded
    end

    def from_cache( request, response )
        return if !(cached = @cache[request.url])

        copy_response_data( cached, response )
        @current_response = cached
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
