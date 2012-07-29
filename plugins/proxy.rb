=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Passive proxy.
#
# Will gather data based on user actions and exchanged HTTP traffic and push that
# data to {Framework#push_to_page_queue} to be audited.
#
# Supports SSL interception.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
#
class Arachni::Plugins::Proxy < Arachni::Plugin::Base

    SHUTDOWN_URL = 'http://arachni.proxy.shutdown/'

    MSG_SHUTDOWN = 'Shutting down the Arachni proxy plug-in...'

    MSG_DISALLOWED = "You can't access this resource via the Arachni " +
                    "proxy plug-in for the following reasons:"

    MSG_NOT_IN_DOMAIN = 'This resource is on a domain or subdomain' +
        ' outside the scope of the audit.'

    MSG_EXCLUDED = 'This resource is matched by an exclude rule.'

    MSG_NOT_INCLUDED = 'This resource is disallowed based on an include rule.'

    def prepare
        # don't let the framework run just yet
        framework.pause
        print_info 'System paused.'

        require framework.opts.dir['plugins'] + '/proxy/server.rb'

        @server = Server.new(
             BindAddress:         options['bind_address'],
             Port:                options['port'],
             ProxyVia:            false,
             ProxyContentHandler: method( :handler ) ,
             ProxyURITest:        method( :allowed? ),
             AccessLog:           [],
             Logger:              WEBrick::Log::new( '/dev/null', 7 )
        )
    end

    def run
        print_status "Listening on: http://#{@server[:BindAddress]}:#{@server[:Port]}"

        print_status "Shutdown URL: #{SHUTDOWN_URL}"
        print_info 'The scan will resume once you visit the shutdown URL.'
        @server.start
    end

    #
    # Called by the proxy to process each request.
    #
    def handler( req, res )
        return res if res.request_method.to_s.downcase == 'connect'

        headers = {}
        headers.merge!( res.header.dup )    if res.header
        headers['set-cookie'] = res.cookies if !res.cookies.empty?

        page = page_from_response( Typhoeus::Response.new(
                effective_url: res.request_uri.to_s,
                body:          res.body,
                headers_hash:  headers,
                method:        res.request_method,
                code:          res.status.to_i
            )
        )
        page = update_forms( page, req ) if req.body
        page = update_framework_cookies( page, req )

        print_info " *  #{page.forms.size} forms"
        print_info " *  #{page.links.size} links"
        print_info " *  #{page.cookies.size} cookies"

        framework.push_to_page_queue( page.dup )
        res
    end

    def update_framework_cookies( page, req )
        print_debug 'Updating framework cookies...'

        cookies = if req['Cookie']
            req['Cookie'].split( ';' ).map do |cookie|
                k, v = cookie.split( '=', 2 )
                Parser::Element::Cookie.new( req.unparsed_uri, k.strip => v.strip )
            end
        else
            []
        end

        if cookies.empty?
            print_debug 'Could not extract cookies...'
            page
        end

        page.cookies |= cookies

        print_debug 'Extracted cookies:'
        cookies.each { |c| print_debug "  * #{c.name} => #{c.value}" }

        framework.http.update_cookies( cookies )
        page
    end

    def update_forms( page, req )
        page.forms << Parser::Element::Form.new( req.unparsed_uri,
            action: req.unparsed_uri,
            method: req.request_method,
            inputs: parse_query( "?#{req.body}" )
        )
        page
    end

    #
    # Checks whether the URL is outside the scope of the scan.
    #
    def allowed?( url )
        print_status "Requesting: #{url}"

        reasons = []

        if shutdown?( url )
            print_status 'Shutting down...'
            @server.shutdown
            reasons << MSG_SHUTDOWN
            return reasons
        end

        reasons << MSG_NOT_IN_DOMAIN if !path_in_domain?( url )
        reasons << MSG_EXCLUDED      if exclude_path?( url )
        reasons << MSG_NOT_INCLUDED  if !include_path?( url )

        if !reasons.empty?
            print_info MSG_DISALLOWED
            reasons.each { |msg| print_info " *  #{msg}" }
            reasons << MSG_DISALLOWED
        end

        reasons
    end

    def shutdown?( url )
        url.to_s == SHUTDOWN_URL
    end

    def clean_up
        framework.resume
    end

    def self.info
        {
            name:        'Proxy',
            description: %q{
                * Gathers data based on user actions and exchanged HTTP
                    traffic and pushes that data to the framework's page-queue to be audited.
                * Updates the framework cookies with the cookies of the HTTP requests and
                    responses, thus it can also be used to login to a web application.
                * Supports SSL interception.

                To skip crawling and only audit elements discovered by using the proxy
                set '--link-count=0'.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            options:     [
                 Options::Port.new( 'port', [false, 'Port to bind to.', 8282] ),
                 Options::Address.new( 'bind_address', [false, 'IP address to bind to.', '0.0.0.0'] )
             ]
        }
    end

end
