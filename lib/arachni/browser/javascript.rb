=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Browser

# Provides access to the {Browser}'s JavaScript environment, mainly helps
# group and organize functionality related to our custom Javascript interfaces.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Javascript
    include UI::Output
    include Utilities

    require_relative 'javascript/proxy'
    require_relative 'javascript/taint_tracer'
    require_relative 'javascript/dom_monitor'

    TOKEN = 'arachni_js_namespace'

    # @return   [String]
    #   URL to use when requesting our custom JS scripts.
    SCRIPT_BASE_URL = 'http://javascript.browser.arachni/'

    # @return   [String]
    #   Filesystem directory containing the JS scripts.
    SCRIPT_LIBRARY  = "#{File.dirname( __FILE__ )}/javascript/scripts/"

    SCRIPT_SOURCES = Dir.glob("#{SCRIPT_LIBRARY}*.js").inject({}) do |h, path|
        h.merge!( path => IO.read(path) )
    end

    NO_EVENTS_FOR_ELEMENTS = Set.new(%w(
        base bdo br head html iframe meta param script style title link hr
    ))

    EACH_DOM_ELEMENT_WITH_EVENTS_BATCH_SIZE = 300

    EVENTS = Set.new([
        :onclick,
        :ondblclick,
        :onmousedown,
        :onmousemove,
        :onmouseout,
        :onmouseover,
        :onmouseup,
        :onload,
        :onsubmit,
        :onselect,
        :onchange,
        :onfocus,
        :onblur,
        :onkeydown,
        :onkeypress,
        :onkeyup,
        :oninput,
        :onselect,
        :onchange,
        :onfocus,
        :onblur,
        :onkeydown,
        :onkeypress,
        :onkeyup,
        :oninput,
        :onchange,
        :onfocus,
        :onblur,
        :onfocus,
        :onblur,
        :onfocus,
        :onblur
    ])

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    attr_accessor :token

    # @return   [String]
    #   Taints to look for and trace in the JS data flow.
    attr_accessor :taint

    # @return   [String]
    #   Inject custom JS code right after the initialization of the custom
    #   JS interfaces.
    attr_accessor :custom_code

    # @return   [DOMMonitor]
    #   {Proxy} for the `DOMMonitor` JS interface.
    attr_reader :dom_monitor

    # @return   [TaintTracer]
    #   {Proxy} for the `TaintTracer` JS interface.
    attr_reader :taint_tracer

    def self.events
        EVENTS
    end

    # @param    [Browser]   browser
    def initialize( browser )
        @browser      = browser
        @taint_tracer = TaintTracer.new( self )
        @dom_monitor  = DOMMonitor.new( self )
    end

    # @return   [Bool]
    #   `true` if there is support for our JS environment in the current page,
    #   `false` otherwise.
    #
    # @see #has_js_initializer?
    def supported?
        # We won't have a response if the browser was steered towards an
        # out-of-scope resource.
        response = @browser.response
        response && has_js_initializer?( response )
    end

    # @param    [HTTP::Response]    response
    #   Response whose {HTTP::Message#body} to check.
    #
    # @return   [Bool]
    #   `true` if the {HTTP::Response response} {HTTP::Message#body} contains
    #   the code for the JS environment.
    def has_js_initializer?( response )
        response.body.include? js_initialization_signal
    end

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    def token
        @token ||= TOKEN
    end

    # @return   [String]
    #   JS code which will call the `TaintTracer.log_execution_flow_sink`,
    #   browser-side, JS function.
    def log_execution_flow_sink_stub( *args )
        taint_tracer.stub.function( :log_execution_flow_sink, *args )
    end

    # @return   [String]
    #   JS code which will call the `TaintTracer.log_data_flow_sink`, browser-side,
    #   JS function.
    def log_data_flow_sink_stub( *args )
        taint_tracer.stub.function( :log_data_flow_sink, *args )
    end

    # @return   [String]
    #   JS code which will call the `TaintTracer.debug`, browser-side JS function.
    def debug_stub( *args )
        taint_tracer.stub.function( :debug, *args )
    end

    # Blocks until the browser page is {#ready? ready}.
    def wait_till_ready
        print_debug_level_2 'Waiting for custom JS...'

        if !supported?
            print_debug_level_2 '...unsupported.'
            return
        end

        t = Time.now
        while !ready?
            sleep 0.1

            if Time.now - t > Options.browser_cluster.job_timeout
                print_debug_level_2 '...timed out.'
                return
            end
        end

        print_debug_level_2 '...done.'
        true
    end

    # @return   [Bool]
    #   `true` if our custom JS environment has been initialized.
    def ready?
        !!run( "return window._#{token}" )
    rescue => e
        print_debug_exception e, 2
        false
    end

    # @param    [String]    script
    #   JS code to execute.
    #
    # @return   [Object]
    #   Result of `script`.
    def run( *args )
        @browser.selenium.execute_script *args
    end

    # Executes the given code but unwraps Watir elements.
    #
    # @param    [String]    script
    #   JS code to execute.
    #
    # @return   [Object]
    #   Result of `script`.
    def run_without_elements( *args )
        unwrap_elements run( *args )
    end

    def has_sinks?
        return false if !supported?
        taint_tracer.has_sinks( @taint )
    end

    # @return   (see TaintTracer#debug)
    def debugging_data
        return [] if !supported?
        taint_tracer.debugging_data
    end

    # @return   (see TaintTracer#execution_flow_sinks)
    def execution_flow_sinks
        return [] if !supported?
        taint_tracer.execution_flow_sinks
    end

    # @return   (see TaintTracer#data_flow_sinks)
    def data_flow_sinks
        return [] if !supported?
        taint_tracer.data_flow_sinks[@taint] || []
    end

    # @return   (see TaintTracer#flush_execution_flow_sinks)
    def flush_execution_flow_sinks
        return [] if !supported?
        taint_tracer.flush_execution_flow_sinks
    end

    # @return   (see TaintTracer#flush_data_flow_sinks)
    def flush_data_flow_sinks
        return [] if !supported?
        taint_tracer.flush_data_flow_sinks[@taint] || []
    end

    # Sets a custom ID attribute to elements with events but without a proper ID.
    def set_element_ids
        return '' if !supported?
        dom_monitor.setElementIds
    end

    # @return   [String]
    #   Digest of the current DOM tree (i.e. node names and their attributes
    #   without text-nodes).
    def dom_digest
        return '' if !supported?
        dom_monitor.digest
    end

    # @return   [String]
    #   Digest of the available DOM events.
    def dom_event_digest
        return '' if !supported?
        dom_monitor.event_digest
    end

    # @note Will not include custom events.
    #
    # @return   [Array<Hash>]
    #   Information about all DOM elements, including any registered event listeners.
    def each_dom_element_with_events( whitelist = [] )
        return if !supported?

        start      = 0
        batch_size = EACH_DOM_ELEMENT_WITH_EVENTS_BATCH_SIZE

        loop do
            elements = dom_monitor.elements_with_events( start, batch_size, whitelist )
            return if elements.empty?

            elements.each do |element|
                next if NO_EVENTS_FOR_ELEMENTS.include? element['tag_name']

                events = {}
                element['events'].each do |event, handlers|
                    events[event.to_sym] = handlers
                end
                element['events'] = events

                yield element
            end

            return if elements.size < batch_size

            start += elements.size
        end
    end

    # @return   [Array<Array>]
    #   Arguments for JS `setTimeout` calls.
    def timeouts
        return [] if !supported?
        dom_monitor.timeouts
    end

    # @param    [HTTP::Request]     request
    #   Request to process.
    # @param    [HTTP::Response]    response
    #   Response to populate.
    #
    # @return   [Bool]
    #   `true` if the request corresponded to a JS file and was served,
    #   `false` otherwise.
    #
    # @see SCRIPT_BASE_URL
    # @see SCRIPT_LIBRARY
    def serve( request, response )
        return false if !request.url.start_with?( SCRIPT_BASE_URL ) ||
            !(script = read_script( request.parsed_url.path ))

        response.code = 200
        response.body = script
        response.headers['content-type']   = 'text/javascript'
        response.headers['content-length'] = script.bytesize
        true
    end

    # @note Will update the `Content-Length` header field.
    #
    # @param    [HTTP::Response]    response
    #   Installs our custom JS interfaces in the given `response`.
    #
    # @see SCRIPT_BASE_URL
    # @see SCRIPT_LIBRARY
    def inject( response )
        # Don't intercept our own stuff!
        return if response.url.start_with?( SCRIPT_BASE_URL )

        # If it's a JS file, update our JS interfaces in case it has stuff that
        # can be tracked.
        #
        # This is necessary because new files can be required dynamically.
        if javascript?( response )

            response.body.insert 0, <<-EOCODE
                #{js_comment}
                #{taint_tracer.stub.function( :update_tracers )};
                #{dom_monitor.stub.function( :update_trackers )};
            EOCODE
            response.body << ";\n"

        # Already has the JS initializer, so it's an HTML response; just update
        # taints and custom code.
        elsif has_js_initializer?( response )

            update_taints( response.body, response )
            update_custom_code( response.body )

        elsif html?( response )

            # Perform an update before each script.
            response.body.gsub!(
                /<script.*?>/i,
                "\\0\n
                #{js_comment}
                #{@taint_tracer.stub.function( :update_tracers )};
                #{@dom_monitor.stub.function( :update_trackers )};\n\n"
            )

            # Perform an update after each script.
            response.body.gsub!(
                /<\/script>/i,
                "\\0\n<script type=\"text/javascript\">" <<
                    "#{@taint_tracer.stub.function( :update_tracers )};" <<
                    "#{@dom_monitor.stub.function( :update_trackers )};" <<
                    "</script> #{html_comment}\n"
            )

            # Include and initialize our JS interfaces.
            response.body.insert 0, <<-EOHTML
<script src="#{script_url_for( :polyfills )}"></script> #{html_comment}
<script src="#{script_url_for( :taint_tracer )}"></script> #{html_comment}
<script src="#{script_url_for( :dom_monitor )}"></script> #{html_comment}
<script>
#{wrapped_taint_tracer_initializer( response )}
#{js_initialization_signal};

#{wrapped_custom_code}
</script> #{html_comment}
            EOHTML

        end

        true
    end

    def javascript?( response )
        response.headers.content_type.to_s.downcase.include?( 'javascript' )
    end

    def html?( response )
        return false if response.body.empty?

        # We only care about HTML responses.
        return false if !response.html?

        # The last check isn't fool-proof, so don't do it when loading the page
        # for the first time, but only when the page loads stuff via AJAX and whatnot.
        #
        # Well, we can be pretty sure that the root page will be HTML anyways.
        return true if @browser.last_url == response.url

        # Finally, verify that we're really working with markup (hopefully HTML)
        # and that the previous checks weren't just flukes matching some other
        # kind of document.
        #
        # For example, it may have been JSON with the wrong content-type that
        # includes HTML -- it happens.
        #
        # Beware, if there's a doctype in the beginning this will get fooled.
        if !Parser.markup?( response.body )
            print_debug "Does not look like HTML: #{response.url}"
            print_debug "\n#{response.body}"
            return false
        end

        true
    end

    private

    def js_comment
        "// Injected by #{self.class}"
    end

    def html_comment
        "<!-- Injected by #{self.class} -->"
    end

    def taints( response )
        taints = {}

        [@taint].flatten.compact.each do |t|
            taints[t] = {
                stop_at_first: false,
                trace:         true
            }
        end

        # Include cookie names and values in the trace so that the browser will
        # be able to infer if they're being used, to avoid unnecessary audits.
        if Options.audit.cookie_doms?
            cookies = begin
                HTTP::Client.cookie_jar.for_url( response.url )
            rescue
                print_debug "Could not get cookies for URL '#{response.url}' from Cookiejar (#{e})."
                print_debug_exception e
                HTTP::Client.cookies
            end

            cookies.each do |c|
                next if c.http_only?

                c.inputs.to_a.flatten.each do |input|
                    next if input.empty?

                    taints[input] ||= {
                        stop_at_first: true,
                        trace:         false
                    }
                end
            end
        end

        taints
    end

    def update_taints( body, response )
        body.gsub!(
            /\/\* #{token}_initialize_start \*\/(.*)\/\* #{token}_initialize_stop \*\//,
            wrapped_taint_tracer_initializer( response )
        )
    end

    def update_custom_code( body )
        body.gsub!(
            /\/\* #{token}_code_start \*\/(.*)\/\* #{token}_code_stop \*\//,
            wrapped_custom_code
        )
    end

    def wrapped_taint_tracer_initializer( response )
        "/* #{token}_initialize_start */ " <<
            "#{@taint_tracer.stub.function( :initialize, taints( response ) )} " <<
            "/* #{token}_initialize_stop */"
    end

    def wrapped_custom_code
        "/* #{token}_code_start */ #{custom_code} /* #{token}_code_stop */"
    end

    def js_initialization_signal
        "window._#{token} = true"
    end

    def read_script( filename )
        @scripts ||= {}
        @scripts[filename] ||=
            SCRIPT_SOURCES[filesystem_path_for_script(filename)].
                gsub( '_token', "_#{token}" )
    end

    def script_exists?( filename )
        SCRIPT_SOURCES.include? filesystem_path_for_script( filename )
    end

    def filesystem_path_for_script( filename )
        @filesystem_path_for_script ||= {}

        @filesystem_path_for_script[filename] ||= begin
            name = "#{SCRIPT_LIBRARY}#{filename}"
            name << '.js' if !name.end_with?( '.js')

            File.expand_path( name )
        end
    end

    def script_url_for( filename )
        if !script_exists?( filename )
            fail ArgumentError,
                 "Script #{filesystem_path_for_script( filename )} does not exist."
        end

        "#{SCRIPT_BASE_URL}#{filename}.js"
    end

    def unwrap_elements( obj )
        case obj
            when Watir::Element
                unwrap_element( obj )

            when Selenium::WebDriver::Element
                unwrap_element( obj )

            when Array
                obj.map { |e| unwrap_elements( e ) }

            when Hash
                obj.each { |k, v| obj[k] = unwrap_elements( v ) }
                obj

            else
                obj
        end
    end

    def unwrap_element( element )
        element.html
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
        ''
    end

end
end
end
