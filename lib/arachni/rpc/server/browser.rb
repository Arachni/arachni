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
    def self.spawn
        socket = "/tmp/arachni-browser-#{Utilities.available_port}"
        token  = Utilities.generate_token

        #Arachni::Processes::Manager.preserve_output
        Arachni::Processes::Manager.fork_em do
            Options.rpc_socket = socket
            new token
        end

        # Wait for the browser to boot up.
        begin
            Timeout.timeout( 10 ) do
                while sleep( 0.1 )
                    begin
                        RPC::Client::Browser.new( socket, token ).alive?
                        break
                    rescue Exception
                    end
                end
            end
        rescue Timeout::Error
            fail "Browser '#{socket}' never started!"
        end

        RPC::Client::Browser.new( socket, token )
    end

    # @param    [String]    token   Authentication token for the clients.
    def initialize( token = nil )
        @browser = Arachni::Browser.new
        @browser.start_capture

        @server = Base.new( Options.instance, token )

        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end

        @server.add_handler( 'browser', self )
        @server.start
    end

    # @param    [Page]  page    Page to analyze.
    # @return   [Array<Page>]
    #   Pages which resulted from firing events, clicking JavaScript links
    #   and capturing AJAX requests.
    #
    # @see Arachni::Browser#shake
    def analyze( page, &block )
        ::EM.defer do
            begin
                @browser.load page
                @browser.shake
            rescue => e
                print_error e
                print_error_backtrace e
            end

            block.call @browser.flush_pages
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
