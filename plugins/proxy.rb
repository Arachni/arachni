=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'erb'
require 'ostruct'

#
# Passive proxy.
#
# Will gather data based on user actions and exchanged HTTP traffic and push that
# data to {Framework#push_to_page_queue} to be audited.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.4
#
class Arachni::Plugins::Proxy < Arachni::Plugin::Base

    BASEDIR  = "#{File.dirname( __FILE__ )}/proxy/"
    BASE_URL = 'http://arachni.proxy/'

    MSG_SHUTDOWN = 'Shutting down the Arachni proxy plug-in...'

    MSG_DISALLOWED = 'You can\'t access this resource via the Arachni ' +
                    'proxy plug-in for the following reasons:'

    MSG_NOT_IN_DOMAIN = 'This resource is on a domain or subdomain' +
        ' outside the scope of the audit.'

    MSG_EXCLUDED = 'This resource is matched by an exclude rule.'

    MSG_NOT_INCLUDED = 'This resource is disallowed based on an include rule.'

    SESSION_TOKEN_COOKIE = 'arachni.proxy.session_token'

    def prepare
        # don't let the framework run just yet
        framework.pause
        print_info 'System paused.'

        require_relative 'proxy/template_scope'
        require_relative 'proxy/server'

        @server = Server.new(
             BindAddress:         options['bind_address'],
             Port:                options['port'],
             ProxyVia:            false,
             ProxyContentHandler: method( :response_handler ),
             ProxyRequestHandler: method( :request_handler ),
             DoNotReverseLookup:  true,
             AccessLog:           [],
             Logger:              WEBrick::Log::new( '/dev/null', 7 ),
             Timeout:             options['timeout']
        )

        @pages = Set.new
        @login_sequence = []
    end

    def run
        print_status "Listening on: http://#{@server[:BindAddress]}:#{@server[:Port]}"

        print_status "Shutdown URL: #{url_for( :shutdown )}"
        print_info 'The scan will resume once you visit the shutdown URL.'

        print_info
        print_info '*' * 82
        print_info '* You need to clear your browser\'s cookies for this site before using the proxy! *'
        print_info '*' * 82
        print_info

        def @server.service( req, res )
            if req.request_method.downcase == 'connect'
                super( req, res )
                return
            end

            super( req, res ) if @config[:ProxyRequestHandler].call( req, res )
        end

        TemplateScope.get.set :params, {}
        @server.start
    end

    def clean_up
        @pages.each { |p| framework.push_to_page_queue( p ) }
        framework.resume
    end

    def prepare_pages_for_inspection
        @pages.select { |p| (p.forms.any? || p.links.any? || p.cookies.any?) && p.text? }
    end

    def vectors_yaml
        vectors = []
        prepare_pages_for_inspection.each do |page|
            page.elements.each do |element|
                next if element.auditable.empty?

                vectors << {
                    type:   element.type,
                    method: element.method,
                    action: element.action,
                    inputs: element.auditable
                }
            end
        end
        vectors.to_yaml
    end

    def request_handler( req, res )
        url = req.request_uri.to_s

        if !system_url?( url ) && skip_path?( url )
            print_info "Ignoring, out of scope: #{url}"
            return true
        end

        # Clear the template scope to prepare it for this request.
        TemplateScope.get.clear

        TemplateScope.get.set :page_count, prepare_pages_for_inspection.size
        TemplateScope.get.set :recording, recording?

        #
        # Bare with me 'cause this is gonna get weird.
        #
        # We need the session cookie to be set for both the domain of the scan
        # target (so that we'll be able to authorize every request) *and*
        # for the domain used for controlling the proxy via the panel
        # (so that we can check those requests too prevent another user
        # from shutting down the proxy).
        #
        p = URI( framework.opts.url )

        # This is the URL we'll use to sign in and set the cookie for the
        # domain of the scan target.
        sign_in_url = "#{p.scheme}://#{p.host}/arachni.proxy.sign_in"

        TemplateScope.get.set :sign_in_url, sign_in_url

        params = parse_request_body( req.body.to_s ).merge( parse_query( url ) ) || {}

        print_status "Requesting #{url}"

        # This is a sign-in request.
        if params['session_token'] == options['session_token']
            # Set us up for the redirection that's coming.
            res.status = 302

            # Set the session cookie.
            res.header['Set-Cookie'] = "#{SESSION_TOKEN_COOKIE}=#{options['session_token']}; path=/"

            # This is the cookie-set request for the domain of the scan target domain...
            if url == sign_in_url && req.request_method == 'POST'
                # ...now we need to set the cookie for the proxy control domain
                # so redirect us to its handler.
                res.header['Location'] = "#{url_for( :sign_in )}?session_token=#{params['session_token']}"

            # This is the cookie-set request for the domain of the proxy control domain...
            elsif url.start_with?( url_for( :sign_in ) )
                # ...time to send the user to the webapp.
                res.header['Location'] = framework.opts.url
            end

            return
        elsif requires_token?( url ) && !valid_session_token?( req )
            print_info MSG_DISALLOWED
            print_info '  * Request does not have a valid session token'

            # Unauthorized.
            res.status = 401
            set_response_body( res, erb( 'sign_in'.to_sym ) )

            return
        end

        if shutdown?( url )
            print_status 'Shutting down...'
            set_response_body( res, erb( :shutdown_message ) )
            @server.shutdown
            return
        end

        @login_sequence << req if recording?

        # Avoid propagating the proxy's session cookie to the webapp.
        req.cookies.reject! { |c| c.name == SESSION_TOKEN_COOKIE }

        if url.start_with? url_for( :panel )
            body =  case '/' + res.request_uri.path.split( '/' )[2..-1].join( '/' )
                        when '/'
                            erb :panel

                        when '/vectors.yml'
                            res.header['Content-Type'] = 'application/x-yaml'

                            erb :vectors,
                                layout:  false,
                                format:  :yml,
                                vectors: vectors_yaml

                        when '/inspect'
                            erb :inspect,
                                pages: prepare_pages_for_inspection

                        when '/help'
                            erb :help

                        when '/record/start'
                            record_start
                            erb :panel

                        when '/record/stop'
                            record_stop
                            erb :verify_login_check, verify_fail: false, params: {
                                'url'     => session.opts.login_check_url,
                                'pattern' => session.opts.login_check_pattern
                            }

                        when '/verify/login_check'

                            if req.request_method != 'POST'
                                erb :verify_login_check, verify_fail: false
                            else
                                session.set_login_check( params['url'], params['pattern'] )

                                if !session.logged_in?
                                    erb :verify_login_check, verify_fail: true
                                else
                                    erb :verify_login_sequence,
                                        params: params,
                                        form:   find_login_form
                                end

                            end

                        when '/verify/login_sequence'

                            session.login_form = find_login_form

                            logged_in = false
                            framework.http.sandbox do |http|
                                http.cookie_jar.clear
                                session.login
                                logged_in = session.logged_in?
                            end

                            erb :verify_login_final, ok: logged_in

                        else
                            res.header['Cache-Control'] = 'max-age=2592000'
                            begin
                                IO.read TemplateScope::PANEL_BASEDIR + '/../' + res.request_uri.path
                            rescue Errno::ENOENT
                                # forbidden
                                res.status = 404
                                erb '404_not_found'.to_sym
                            end
                        end.to_s
            set_response_body( res, body )
            return
        end

        true
    end

    def requires_token?( url )
        !(asset?( url ) || url.start_with?( url_for( :sign_in ) ))
    end

    def valid_session_token?( req )
        session_token = options['session_token']
        return true if options['session_token'].to_s.empty?

        cookies_to_hash( req.cookies )[SESSION_TOKEN_COOKIE] == session_token
    end

    def recording?
        @record ||= false
    end

    def record_start
        @login_sequence = []
        @record = true
    end
    def record_stop
        @record = false
    end

    #
    # Tries to determine which form is the login one from the logged requests in
    # the recorded login sequence.
    #
    # @return   [Array<Arachni::Element::Form>]
    #
    def find_login_form
        @login_sequence.each do |r|
            form = find_login_form_from_request( r )
            return form if form
        end
        nil
    end

    #
    # Goes through all forms which contain password fields and tries to match
    # them to the given request.
    #
    # @param    [WEBrick::HTTPRequest]  request
    #
    # @return   [Array<Arachni::Element::Form>]
    #
    # @see #forms_with_password
    #
    def find_login_form_from_request( request )
        return if (params = parse_request_body( request.body )).empty?

        f = session.find_login_form( pages:  @pages.to_a,
                                     action: normalize_url( request.request_uri.to_s ),
                                     inputs: params.keys )

        return if !f
        f.update( params )
    end

    #
    # Goes through the logged pages and returns all forms which contain password fields
    #
    # @return   [Array<Arachni::Element::Form>]
    #
    def forms_with_password
        @pages.map { |p| p.forms.select { |f| f.requires_password? } }.flatten
    end

    #
    # Called by the proxy for each response.
    #
    def response_handler( req, res )
        if res.request_method.to_s.downcase == 'connect' ||
            skip_path?( res.request_uri.to_s )
            return res
        end

        headers = {}
        headers.merge!( res.header.dup )    if res.header
        headers['set-cookie'] = res.cookies if !res.cookies.empty?

        page = page_from_response( Typhoeus::Response.new(
                effective_url: res.request_uri.to_s,
                body:          res.body.dup,
                headers_hash:  headers,
                method:        res.request_method,
                code:          res.status.to_i,
                request:       Typhoeus::Request.new( req.request_uri.to_s )
            )
        )
        page = update_forms( page, req, res ) if req.body

        print_info " *  #{page.forms.size} forms"
        print_info " *  #{page.links.size} links"
        print_info " *  #{page.cookies.size} cookies"

        @pages << page.dup

        inject_panel( res )
    end

    def inject_panel( res )
        return res if !res.header['content-type'].to_s.start_with?( 'text/html' ) ||
                        !(body_tag = res.body.match( /<(\s*)body(.*)>/i ))

        res.body.gsub!( body_tag.to_s, "#{body_tag}#{panel_iframe}" )
        res.header['content-length'] = res.body.size.to_s
        res
    end

    def cookies_to_hash( cookies )
        cookies.inject({}) { |h, c| h[c.name] = c.value; h }
    end

    def panel_iframe
        <<-HTML
            <style type='text/css'>
                .panel {
                    left:   0px;
                    top:    0px;
                    margin: 0px;
                    width:  100%;
                    height: 50px;
                    border: 0px;
                    position:fixed;
                }
                body {
                    padding-top: 40px;
                }
            </style>
            <iframe class='panel' src='#{TemplateScope::PANEL_URL}'></iframe>
        HTML
    end

    def erb( *args )
        TemplateScope.get.erb( *args )
    end

    def update_forms( page, req, res )
        page.forms << Form.new( res.request_uri.to_s,
            action: res.request_uri.to_s,
            method: req.request_method,
            inputs: form_parse_request_body( req.body )
        )
        page
    end

    def system_url?( url )
        url.start_with? BASE_URL
    end

    def shutdown?( url )
        url.to_s.start_with? url_for( :shutdown )
    end

    def set_response_body( res, body )
        res.body = body
        res.header['content-length'] = res.body.size.to_s
        res.header['content-type'] = 'text/html' if body =~ /<(\s)*html(\s*)(.*?)>/i
        res
    end

    def asset?( url )
        url.start_with?( "#{url_for( :panel )}/css/" ) ||
            url.start_with?( "#{url_for( :panel )}/js/" ) ||
            url.start_with?( "#{url_for( :panel )}/img/" )
    end

    def self.url_for( type )
        {
            shutdown: "#{BASE_URL}shutdown",
            panel:    "#{BASE_URL}panel",
            inspect:  "#{BASE_URL}panel/inspect",
            sign_in:  "#{BASE_URL}sign_in",
        }[type]
    end
    def url_for( *args )
        self.class.url_for( *args )
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
                * Authorization via a configurable session token.

                To skip crawling and only audit elements discovered by using the proxy
                set the link-count limit option to 0.

                NOTICE:
                    The 'session_token' will be looked for in a cookie named
                    'arachni.proxy.session_token', so if you choose to use a token to
                    restrict access to the proxy and need to pass traffic through the
                    proxy programmatically please configure your HTTP client with
                    a cookie named 'arachni.proxy.session_token' with the value of
                    the 'session_token' option.

                WARNING:
                    The 'session_token' option is not a way to secure usage of
                    this proxy but rather a way to restrict usage enough to avoid
                    users unwittingly interfering with each others' sessions.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.4',
            options:     [
                 Options::Port.new( 'port', [false, 'Port to bind to.', 8282] ),
                 Options::Address.new( 'bind_address',
                                       [false, 'IP address to bind to.', '0.0.0.0'] ),
                 Options::String.new( 'session_token',
                                      [false, 'A session token to demand from ' +
                                          'users before allowing them to use the proxy.', ''] ),
                 Options::Int.new( 'timeout',
                                   [false, 'How long to wait for a request to ' +
                                       'complete, in milliseconds.', 20000] )
             ]
        }
    end

end
