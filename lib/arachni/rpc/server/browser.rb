=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end


module Arachni

lib = Options.paths.lib
require lib + 'rpc/server/base'
require lib + 'rpc/server/browser/peer'
require lib + 'rpc/client/browser'
require lib + 'processes'
require lib + 'framework'

module RPC
class Server

# Provides a remote {Arachni::Browser} worker allowing to off-load the
# overhead of DOM/JS/AJAX analysis to a separate process.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Browser
    include UI::Output

    # @param    [Hash]    options
    # @option   [String]    :token  Authentication token for the clients.
    def initialize( options = {} )
        %w(QUIT INT).each do |signal|
            trap( signal, 'IGNORE' ) if Signal.list.has_key?( signal )
        end

        token    = options.delete( :token )
        @browser = Peer.new( options )

        @server = Base.new( Options.instance, token )
        @server.logger.level = ::Logger::Severity::FATAL

        @server.add_async_check do |method|
            # Methods that expect a block are async.
            method.parameters.flatten.include? :block
        end

        @server.add_handler( 'browser', self )
        @server.start
    end

    # @param    [Browser::Request]  request
    # @param    [Hash]  options
    # @option   options [Array<Cookie>] :cookies
    #   Cookies with which to update the browser's cookie-jar before analyzing
    #   the given resource.
    #
    # @return   [Array<Page>]
    #   Pages which resulted from firing events, clicking JavaScript links
    #   and capturing AJAX requests.
    #
    # @see Arachni::Browser#trigger_events
    def process_request( request, options = {}, &block )
        HTTP::Client.update_cookies( options[:cookies] || [] )

        ::EM.defer do
            begin
                @browser.load request.resource

                if request.single_event?
                    @browser.trigger_event(
                        request.resource, request.element_index, request.event
                    )
                else
                    @browser.trigger_events
                end
            rescue => e
                print_error e
                print_error_backtrace e
            ensure
                @browser.close_windows
            end

            # If there's a master which handles pages as they are captured
            # there's no need to send anything back here.
            block.call( @browser.master ? nil : @browser.flush_pages )
        end

        true
    end

    # @return   [Bool]  `true`
    def alive?
        true
    end

    # Closes the browser and shuts down the server.
    #
    # @see Arachni::Browser#close_windows
    def close
        @browser.shutdown rescue nil
        @server.shutdown rescue nil
        nil
    end
    alias :shutdown :close

end

end
end
end
