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
    # @return   [Client::Browser]
    def self.spawn( master = nil )
        socket = "/tmp/arachni-browser-#{Utilities.available_port}"
        token  = Utilities.generate_token

        ::EM.fork_reactor do
            Options.rpc_socket = socket
            new master: master, token: token
        end
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

        client
    end

    # @param    [Hash]    options
    # @option   [String]    :token  Authentication token for the clients.
    def initialize( options = {} )
        %w(QUIT INT).each do |signal|
            trap( signal, 'IGNORE' ) if Signal.list.has_key?( signal )
        end

        token = options.delete( :token )
        if (@master = options.delete( :master ))
            options[:store_pages] = false
        end

        @browser = Arachni::Browser.new( options )
        @browser.start_capture

        if @master
            @browser.on_new_page do |page|
                @master.handle_page page
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
                @browser.load resource
                @browser.explore
            rescue => e
                print_error e
                print_error_backtrace e
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
        @browser.close rescue nil
        @server.shutdown rescue nil
        nil
    end
    alias :shutdown :close

end

end
end
end
