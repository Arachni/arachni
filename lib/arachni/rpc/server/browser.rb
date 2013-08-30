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


module Arachni

lib = Options.dir['lib']
require lib + 'rpc/server/base'
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

    # Spawns a {Server::Browser} in it own process and connects to it.
    #
    # @param    [Hash]  options
    # @option   options  :master [#handle_page]
    #   Master to be passed each page.
    # @option   options  :wait [Bool]
    #   `true` to wait until the {Browser} has booted, `false` otherwise.
    #
    # @return   [Array, Client::Browser]
    #
    #   * `[socket, token]` if `:wait` has been set to `false`.
    #   * {Client::Browser} if `:wait` has been set to `true`.
    def self.spawn( options = {} )
        socket = "/tmp/arachni-browser-#{Utilities.available_port}"
        token  = Utilities.generate_token

        ::EM.fork_reactor do
            Options.rpc_socket = socket
            new master: options[:master], token: token, shared_token: options[:shared_token]
        end

        if options[:wait]
            sleep 0.1 while !File.exists?( socket )

            client = RPC::Client::Browser.new( socket, token )
            begin
                Timeout.timeout( 10 ) do
                    while sleep( 0.1 )
                        begin
                            client.alive?
                            break
                        rescue Exception
                        end
                    end
                end
            rescue Timeout::Error
                abort "Browser '#{socket}' never started!"
            end

            return client
        end

        [socket, token]
    end

    # @param    [Hash]    options
    # @option   [String]    :token  Authentication token for the clients.
    def initialize( options = {} )
        %w(QUIT INT).each do |signal|
            trap( signal, 'IGNORE' ) if Signal.list.has_key?( signal )
        end

        token = options.delete( :token )
        if (@master = options[:master])
            options[:store_pages] = false
        end

        @browser = Arachni::Browser.new( options )
        @browser.start_capture

        if @master

            # Let the master handle deduplication of operations.
            def @browser.skip?( action )
                @options[:master].skip? action
            end

            def @browser.skip( action )
                @options[:master].skip action
            end

            def @browser.distribute_event( *args )
                @options[:master].analyze args
                true
            end

            @browser.on_new_page do |page|
                @master.handle_page( page ){}
            end
        end

        @server = Base.new( Options.instance, token )
        @server.logger.level = ::Logger::Severity::FATAL

        @server.add_async_check do |method|
            # Methods that expect a block are async.
            method.parameters.flatten.include? :block
        end

        @server.add_handler( 'browser', self )
        @server.start
    end

    # @param    [Page, String, HTTP::Response]  resource
    #   Resource to analyze. If `String` is given it will be treated as a URL.
    # @param    [Hash]  options
    # @option   options [Array<Cookie>] :cookies
    #   Cookies with which to update the browser's cookie-jar before analyzing
    #   the given resource.
    #
    # @return   [Array<Page>]
    #   Pages which resulted from firing events, clicking JavaScript links
    #   and capturing AJAX requests.
    #
    # @see Arachni::Browser#explore
    def analyze( resource, options = {}, &block )
        HTTP::Client.update_cookies( options[:cookies] || [] )

        ::EM.defer do
            begin
                # If it's an array it's an event triggering operation that was
                # distributed across the cluster to make analyzing a single
                # page faster.
                if resource.is_a? Array
                    @browser.load resource.first
                    @browser.trigger_event *resource

                # Otherwise it's a seed page/url/response that needs to be
                # analyzed.
                else
                    @browser.load resource
                    @browser.explore
                end
            rescue => e
                print_error e
                print_error_backtrace e
            ensure
                @browser.close_windows
            end

            # If there's a master which handles pages as they are captured
            # there's no need to send anything back here.
            block.call( @master ? nil : @browser.flush_pages )
        end

        true
    end

    # @return   [Bool]  `true`
    def alive?
        true
    end

    # Closes the browser and shuts down the server.
    #
    # @see Arachni::Browser#close
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
