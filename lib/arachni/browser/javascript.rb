=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser

# Provides access to the {Browser}'s JavaScript environment, mainly helps
# group and organize functionality related to Javascript/DOM overrides.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Javascript
    include UI::Output
    include Utilities

    # @return [String]
    #   Path to JS code which should be placed at the beginning of each page
    #   in order to override standard DOM and JS functions and thus provide us
    #   with more information for deeper analysis.
    OVERRIDES = IO.read( "#{File.dirname( __FILE__ )}/javascript/overrides.js" )

    # @return   [String]
    #   JavaScript token used to namespace the {OVERRIDES} and avoid clashes.
    attr_accessor :token

    # @return   [String]    Taint to look for and trace in the JS data flow.
    attr_accessor :taint

    # @param    [Browser]   browser
    def initialize( browser )
        @browser = browser
    end

    # @return   [String]
    #   JavaScript token used to namespace the {OVERRIDES} and avoid clashes.
    def token
        @token ||= generate_token.to_s
    end

    # @return   [String]    JS code which will call the `log_sink` JS function.
    def log_sink_stub( data = nil )
        "_#{token}.log_sink(#{data.to_json if data})"
    end

    # @return [String]
    #   {OVERRIDES} with `_token` substituted with "_{#token}".
    def overrides
        @overrides ||= OVERRIDES.gsub( '_token', "_#{token}" )
    end

    # @note Will update the `Content-Length`.
    # @param    [HTTP::Response]    response
    #   Installs {OVERRIDES} in the given `response`.
    # @return   [HTTP::Response] Updated response.
    def install_overrides( response )
        return if response.body.include? "#{token}.override"

        response.body.gsub!(
            /<script(.*?)>/i,
            # This will let us override and trace all global functions.
            "<script\\1>\n_#{token}.update_tracers();\n"
        )

        response.body = "\n<script>
            #{overrides}
        #{"_#{token}.taint = #{@taint.inspect};" if @taint}
</script>\n#{response.body}"

        #response.body.sub!(
        #    /<\/script(.*?)>/i,
        #    "\n<script>
        #        #{overrides}
        #        #{"_#{token}.taint = #{@taint.inspect};" if @taint}
        #    </script>\n</script\\1>"
        #)

        response.headers['content-length'] = response.body.bytesize
        response
    end

    # Blocks until the browser page is {#ready? ready}.
    def wait_till_ready
        return if !@browser.response || !@browser.response.body.include?( token )
        sleep 0.1 while !ready?
    end

    # @return   [Bool]
    #   `true` if the page is ready and {OVERRIDES} has been installed, `false`
    #   otherwise.
    def ready?
        #!!run( "return _#{token}" ) rescue false
        begin
            run( "return _#{token}" )
        rescue => e
            ap e
            ap e.backtrace
            false
        end
        true
    end

    # @param    [String]    script  JS code to execute.
    # @return   [Object]    Result of `script`.
    def run( script )
        @browser.watir.execute_script script
    end

    # @return   [Array<Object>]
    #   Data logged by {OVERRIDES override} function `_token.debug`.
    def debugging_data
        prepare_sink_data( get_override( :debugging_data ) )
    end

    # @return   [Array<Object>]
    #   Data logged by {OVERRIDES override} function `_token.send_to_sink`.
    def sink
        prepare_sink_data( get_override( :sink ) )
    end

    # @return   [Array<Object>]
    #   Returns {#sink} data and empties the {OVERRIDES} `_token.sink`.
    def flush_sink
        prepare_sink_data( get_override( 'flush_sink()' ) )
    end

    # @param   [String]    property
    #   Returns a given property or execute the given function from the
    #   {OVERRIDES} namespace.
    def get_override( property )
        return if !ready?
        run "return _#{token}.#{property};"
    end

    # @return   [Array<Array>] Arguments for JS `setTimeout` calls.
    def timeouts
        get_override( 'setTimeouts' ) || []
    end

    # @return   [Array<Array>] Arguments for JS `setInterval` calls.
    def intervals
        get_override( 'setIntervals' ) || []
    end

    private

    def prepare_sink_data( sink_data )
        return [] if !sink_data

        sink_data.map do |entry|
            {
                data:  entry['data'],
                trace: prepare_js_trace( entry['trace'] )
            }
        end
    end

    def prepare_js_trace( trace )
        to_string = Set.new(%w(toElement target srcElement currentTarget fromElement))

        formatted = []
        trace.each do |entry|
            entry = entry.symbolize_keys( false )

            if entry[:arguments] && entry[:arguments][0].is_a?( Hash ) &&
                entry[:arguments][0].include?( 'target' )

                #entry[:arguments][0].each do |k, v|
                #    entry[:arguments][0][k] =
                #        (v && to_string.include?( k ) ? v.html : v)
                #end
            end

            formatted << entry
        end

        formatted
    end

end
end
end
