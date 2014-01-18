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

    # @return   [String]    URL to use when requesting our custom JS scripts.
    SCRIPT_BASE_URL = 'http://javascript.browser.arachni/'

    # @return   [String]    Filesystem directory containing the JS scripts.
    SCRIPT_LIBRARY  = "#{File.dirname( __FILE__ )}/javascript/scripts/"

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    attr_accessor :token

    # @return   [String]    Taint to look for and trace in the JS data flow.
    attr_accessor :taint

    # @return   [Proxy] Proxy for the `DOMMonitor` JS interface.
    attr_reader :dom_monitor

    # @return   [Proxy] Proxy for the `TaintTracer` JS interface.
    attr_reader :taint_tracer

    # @param    [Browser]   browser
    def initialize( browser )
        @browser = browser

        @dom_monitor  = Proxy.new( self, 'DOMMonitor' )
        @taint_tracer = Proxy.new( self, 'TaintTracer' )
    end

    # @return   [Bool]
    #   `true` if there is support for our JS environment in the current page,
    #   `false` otherwise.
    def supported?
        @browser.response.body.include? js_initialization_signal
    end

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    def token
        @token ||= generate_token.to_s
    end

    # @return   [String]    JS code which will call the `log_sink` JS function.
    def log_sink_stub( *args )
        taint_tracer.stub.function( :log_sink, *args )
    end

    # @return   [String]    JS code which will call the `debug` JS function.
    def debug_stub( *args )
        taint_tracer.stub.function( :debug, *args )
    end

    # Blocks until the browser page is {#ready? ready}.
    def wait_till_ready
        return if !@browser.response || !@browser.response.body.include?( token )
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
    #   Data logged by function `_token.debug`.
    def debugging_data
        return [] if !supported?
        prepare_sink_data( taint_tracer.debugging_data )
    end

    # @return   [Array<Object>]
    #   Data logged by function `_token.send_to_sink`.
    def sink
        return [] if !supported?
        prepare_sink_data( taint_tracer.sink )
    end

    # @return   [Array<Object>]
    #   Returns {#sink} data and empties the `_token.sink`.
    def flush_sink
        return [] if !supported?
        prepare_sink_data( taint_tracer.flush_sink )
    end

    # @return   [Array<Array>] Arguments for JS `setTimeout` calls.
    def timeouts
        return [] if !supported?
        dom_monitor.setTimeouts
    end

    # @return   [Array<Array>] Arguments for JS `setInterval` calls.
    def intervals
        return [] if !supported?
        dom_monitor.setIntervals
    end

    # @param    [HTTP::Client::Request]     request Request to process.
    # @param    [HTTP::Client::Response]    response Response to populate.
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
        response.headers['content-type'] = 'text/javascript'
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
        return false if response.body.include? js_initialization_signal

        # If we've got no taint to trace don't bother...
        if @taint
            # Schedule a tracer update at the beginning of each script block in order
            # to put our hooks into any newly introduced functions.
            #
            # The fact that our update call seems to be taking place before any
            # functions get the chance to be defined doesn't seem to matter.
            response.body.gsub!(
                /<script(.*?)>/i,
                "\\0\n#{@taint_tracer.stub.function( :update_tracers )}; // Injected by #{self.class}\n"
            )

            # Also perform an update after each script block, this is for external
            # scripts.
            response.body.gsub!(
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
            </script> <!-- Script injected by #{self.class} -->

            #{response.body}
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
                gsub( '_token', "_#{token}" )
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

    def prepare_sink_data( sink_data )
        return [] if !sink_data

        sink_data.map do |entry|
            {
                data:  entry['data'],
                trace: [entry['trace']].flatten.compact.
                           map { |h| h.symbolize_keys( false ) }
            }
        end
    end

end
end
end
