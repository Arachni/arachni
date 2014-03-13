=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser

# Provides access to the {Browser}'s JavaScript environment, mainly helps
# group and organize functionality related to our custom Javascript interfaces.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Javascript
    include UI::Output
    include Utilities

    require_relative 'javascript/proxy'
    require_relative 'javascript/taint_tracer'
    require_relative 'javascript/dom_monitor'

    # @return   [String]    URL to use when requesting our custom JS scripts.
    SCRIPT_BASE_URL = 'http://javascript.browser.arachni/'

    # @return   [String]    Filesystem directory containing the JS scripts.
    SCRIPT_LIBRARY  = "#{File.dirname( __FILE__ )}/javascript/scripts/"

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    attr_accessor :token

    # @return   [String]    Taint to look for and trace in the JS data flow.
    attr_accessor :taint

    # @return   [String]
    #   Inject custom JS code right after the initialization of the custom
    #   JS interfaces.
    attr_accessor :custom_code

    # @return   [DOMMonitor] {Proxy} for the `DOMMonitor` JS interface.
    attr_reader :dom_monitor

    # @return   [TaintTracer] {Proxy} for the `TaintTracer` JS interface.
    attr_reader :taint_tracer

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
    #   Response whose {HTTP::Response#body} to check.
    # @return   [Bool]
    #   `true` if the {HTTP::Response response} {HTTP::Response#body} contains
    #   the code for the JS environment.
    def has_js_initializer?( response )
        response.body.include? js_initialization_signal
    end

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    def token
        @token ||= generate_token.to_s
    end

    # @return   [String]
    #   JS code which will call the `log_execution_flow_sink` JS function.
    def log_execution_flow_sink_stub( *args )
        taint_tracer.stub.function( :log_execution_flow_sink, *args )
    end

    # @return   [String]
    #   JS code which will call the `data_flow_sink` JS function.
    def log_data_flow_sink_stub( *args )
        taint_tracer.stub.function( :log_data_flow_sink, *args )
    end

    # @return   [String]    JS code which will call the `debug` JS function.
    def debug_stub( *args )
        taint_tracer.stub.function( :debug, *args )
    end

    # Blocks until the browser page is {#ready? ready}.
    def wait_till_ready
        return if !supported?
        sleep 0.1 while !ready?
    end

    # @return   [Bool] `true` if the page is ready.
    def ready?
        !!run( "return window._#{token}" ) rescue false
    end

    # @param    [String]    script  JS code to execute.
    # @return   [Object]    Result of `script`.
    def run( script )
        @browser.watir.execute_script script
    end

    # @return   [Array<Object>]
    #   Data logged by function `TaintTracer.debug`.
    def debugging_data
        return [] if !supported?
        taint_tracer.debugging_data
    end

    # @return   [Array<Object>]
    #   Data logged by function `TaintTracer.log_execution_flow_sink`.
    def execution_flow_sink
        return [] if !supported?
        taint_tracer.execution_flow_sink
    end

    # @return   [Array<Object>]
    #   Data logged by function `TaintTracer.data_flow_sink`.
    def data_flow_sink
        return [] if !supported?
        taint_tracer.data_flow_sink
    end

    # @return   [Array<Object>]
    #   Returns {#execution_flow_sink} data and empties the
    #   `TaintTracer.execution_flow_sink`.
    def flush_execution_flow_sink
        return [] if !supported?
        taint_tracer.flush_execution_flow_sink
    end

    # @return   [Array<Object>]
    #   Returns {#data_flow_sink} data and empties the
    #   `TaintTracer.data_flow_sink`.
    def flush_data_flow_sink
        return [] if !supported?
        taint_tracer.flush_data_flow_sink
    end

    # @return   [String]
    #   Digest of the current DOM tree (i.e. node names and their attributes
    #   without text-nodes).
    def dom_digest
        return '' if !supported?
        dom_monitor.digest
    end

    # @return   [Array<Hash>]
    #   Information about all DOM elements, including any registered event listeners.
    def dom_elements_with_events
        return [] if !supported?
        dom_monitor.elements_with_events
    end

    # @return   [Array<Array>] Arguments for JS `setTimeout` calls.
    def timeouts
        return [] if !supported?
        dom_monitor.timeouts
    end

    # @return   [Array<Array>] Arguments for JS `setInterval` calls.
    def intervals
        return [] if !supported?
        dom_monitor.intervals
    end

    # @param    [HTTP::Request]     request Request to process.
    # @param    [HTTP::Response]    response Response to populate.
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
    # @param    [HTTP::Response]    response
    #   Installs our custom JS interfaces in the given `response`.
    # @return   [Bool]
    #   `true` if injection was performed, `false` otherwise (in case our code
    #   is already present).
    #
    # @see SCRIPT_BASE_URL
    # @see SCRIPT_LIBRARY
    def inject( response )
        return false if has_js_initializer?( response )

        body = response.body.dup

        # If we've got no taint to trace don't bother...
        if @taint
            # Schedule a tracer update at the beginning of each script block in order
            # to put our hooks into any newly introduced functions.
            #
            # The fact that our update call seems to be taking place before any
            # functions get the chance to be defined doesn't seem to matter.
            body.gsub!(
                /<script(.*?)>/i,
                "\\0\n#{@taint_tracer.stub.function( :update_tracers )}; // Injected by #{self.class}\n"
            )

            # Also perform an update after each script block, this is for external
            # scripts.
            body.gsub!(
                /<\/script>/i,
                "\\0\n<script type=\"text/javascript\">#{@taint_tracer.stub.function( :update_tracers )}" <<
                    "</script> <!-- Script injected by #{self.class} -->\n"
            )
        end

        response.body = <<-EOHTML
            <script src="#{script_url_for( :taint_tracer )}"></script> <!-- Script injected by #{self.class} -->
            <script> #{@taint_tracer.stub.function( :initialize, @taint )} </script> <!-- Script injected by #{self.class} -->

            <script src="#{script_url_for( :dom_monitor )}"></script> <!-- Script injected by #{self.class} -->
            <script>
                #{@dom_monitor.stub.function( :initialize )};
                #{js_initialization_signal};

                #{custom_code}
            </script> <!-- Script injected by #{self.class} -->

            #{body}
        EOHTML

        response.headers['content-length'] = response.body.bytesize
        true
    end

    private

    def js_initialization_signal
        "window._#{token} = true"
    end

    def read_script( filename )
        @scripts ||= {}
        @scripts[filename] ||=
            IO.read( filesystem_path_for_script( filename ) ).
                gsub( '_token', "_#{token}" ).freeze
    end

    def script_exists?( filename )
        (!!read_script( filename )) rescue false
    end

    def filesystem_path_for_script( filename )
        name = "#{SCRIPT_LIBRARY}#{filename}"
        name << '.js' if !name.end_with?( '.js')
        name
    end

    def script_url_for( filename )
        if !script_exists?( filename )
            fail ArgumentError,
                 "Script #{filesystem_path_for_script( filename )} does not exist."
        end

        "#{SCRIPT_BASE_URL}#{filename}.js"
    end

end
end
end
