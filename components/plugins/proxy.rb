=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'erb'
require 'ostruct'

# Passive proxy.
#
# Will gather data based on user actions and exchanged HTTP traffic and push that
# data to {Arachni::Framework#push_to_page_queue} to be audited.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
        require_relative 'proxy/template_scope'

        @server = Arachni::HTTP::ProxyServer.new(
             address:          options[:bind_address],
             port:             options[:port],
             response_handler: method( :response_handler ),
             request_handler:  method( :request_handler ),
             timeout:          options[:timeout]
        )

        @pages       = Set.new
        @pages_mutex = Mutex.new
        @login_sequence = []

        framework_pause
    end

    def run
        print_status "Listening on: #{@server.url}"

        print_info "Control panel URL: #{url_for( :panel )}"
        print_info "Shutdown URL:      #{url_for( :shutdown )}"
        print_info 'The scan will resume once you visit the shutdown URL.'
        print_info
        print_info 'When browsing HTTPS sites, please accept the Arachni SSL certificate' +
            ' or install the CA certificate manually from:'
        print_info "    #{Arachni::HTTP::ProxyServer::SSLInterceptor::CA_CERTIFICATE}"
        print_info
        print_bad '**DO NOT** forget to revoke it after using the proxy, as it' +
            ' can be used by anyone to impersonate 3rd party servers.'
        print_info
        print_info '*' * 82
        print_info '* You need to clear your browser\'s cookies for this site before using the proxy! *'
        print_info '*' * 82
        print_info

        TemplateScope.get.set :params, {}

        @server.start_async

        wait_while_framework_running
    end

    def clean_up
        return if @cleaned_up
        @cleaned_up = true

        @server.shutdown

        @pages_mutex.synchronize do
            @pages.each { |p| framework.push_to_page_queue( p, true ) }
        end

        framework_resume
    end

    def vectors_yaml
        vectors = []
        prepare_pages_for_inspection.each do |page|
            page.elements.each do |element|
                next if element.inputs.empty?

                data = {
                    type:   element.type,
                    method: element.method,
                    action: element.action,
                    inputs: element.inputs
                }

                if element.respond_to? :source
                    data[:source] = element.source
                end

                vectors << data
            end
        end
        vectors.to_yaml
    end

    def request_handler( req, res )
        url = req.url

        if !system_url?( url ) && req.scope.out?
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
        p = URI( framework.options.url )

        # This is the URL we'll use to sign in and set the cookie for the
        # domain of the scan target.
        sign_in_url = "#{p.scheme}://#{p.host}/arachni.proxy.sign_in"

        TemplateScope.get.set :sign_in_url, sign_in_url

        params = request_parse_body( req.body.to_s ).
            merge( uri_parse_query( url ) ) || {}

        print_status "Requesting #{url}"

        # This is a sign-in request.
        if params['session_token'] == options[:session_token].to_s
            # Set us up for the redirection that's coming.
            res.code = 302

            # Set the session cookie.
            res.headers['Set-Cookie'] = "#{SESSION_TOKEN_COOKIE}=#{options[:session_token]}; path=/"

            # This is the cookie-set request for the domain of the scan target domain...
            if url == sign_in_url && req.method == :post

                # ...now we need to set the cookie for the proxy control domain
                # so redirect us to its handler.
                res.headers['Location'] = "#{url_for( :sign_in )}?session_token=#{options[:session_token]}"

            # This is the cookie-set request for the domain of the proxy control domain...
            elsif url.start_with?( url_for( :sign_in ) )

                # ...time to send the user to the webapp.
                res.headers['Location'] = framework.options.url
            end

            return
        elsif requires_token?( url ) && !valid_session_token?( req )
            print_info MSG_DISALLOWED
            print_info '  * Request does not have a valid session token'

            # Unauthorized.
            res.code = 401
            set_response_body( res, erb( 'sign_in'.to_sym ) )

            return
        end

        if shutdown?( url )
            print_status 'Shutting down...'
            set_response_body( res, erb( :shutdown_message ) )
            clean_up
            return
        end

        @login_sequence << req if recording?

        # Avoid propagating the proxy's session cookie to the webapp.
        req.cookies.delete SESSION_TOKEN_COOKIE

        res.code = 200

        if url.start_with? url_for( :panel )
            body =  case '/' + res.parsed_url.path.split( '/' )[2..-1].join( '/' )
                        when '/'
                            TemplateScope.get.set :pages, prepare_pages_for_inspection
                            erb :panel

                        when '/vectors.yml'
                            res.headers['Content-Type'] = 'application/x-yaml'

                            erb :vectors,
                                layout:  false,
                                format:  :yml,
                                vectors: vectors_yaml

                        when '/help'
                            erb :help

                        when '/record/start'
                            record_start
                            erb :panel

                        when '/record/stop'
                            record_stop
                            erb :verify_login_check, verify_fail: false, params: {
                                'url'     => framework.options.session.check_url,
                                'pattern' => framework.options.session.check_pattern
                            }

                        when '/verify/login_check'

                            if req.method != :post
                                erb :verify_login_check, verify_fail: false
                            else
                                framework.options.session.check_url     = params['url']
                                framework.options.session.check_pattern = params['pattern']

                                if !session.logged_in?
                                    erb :verify_login_check,
                                        params:      params,
                                        verify_fail: true
                                else
                                    erb :verify_login_sequence,
                                        params: params,
                                        form:   find_login_form
                                end

                            end

                        when '/verify/login_sequence'
                            login_form = find_login_form
                            session.configure(
                                url:    login_form.url,
                                inputs: login_form.inputs
                            )

                            logged_in = false
                            framework.http.sandbox do |http|
                                http.cookie_jar.clear
                                session.login
                                logged_in = session.logged_in?
                            end

                            erb :verify_login_final, ok: logged_in

                        else
                            res.headers['Cache-Control'] = 'max-age=2592000'
                            begin
                                IO.read TemplateScope::PANEL_BASEDIR + '/../' + res.parsed_url.path
                            rescue Errno::ENOENT
                                # forbidden
                                res.code = 404
                                erb '404_not_found'.to_sym
                            end
                        end.to_s
            set_response_body( res, body )
            return
        end

        true

    rescue => e
        ap e
        ap e.backtrace
    end

    def requires_token?( url )
        !(asset?( url ) || url.start_with?( url_for( :sign_in ) ))
    end

    def valid_session_token?( request )
        session_token = options[:session_token]
        return true if session_token.to_s.empty?

        request.effective_cookies[SESSION_TOKEN_COOKIE] == session_token
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

    # Tries to determine which form is the login one from the logged requests in
    # the recorded login sequence.
    #
    # @return   [Array<Arachni::Element::Form>]
    def find_login_form
        @login_sequence.each do |r|
            form = find_login_form_from_request( r )
            return form if form
        end
        nil
    end

    # Goes through all forms which contain password fields and tries to match
    # them to the given request.
    #
    # @param    [HTTP::Request]  request
    #
    # @return   [Array<Arachni::Element::Form>]
    #
    # @see #forms_with_password
    def find_login_form_from_request( request )
        return if (params = request_parse_body( request.body )).empty?

        f = @pages_mutex.synchronize do
            session.find_login_form(
                pages:  @pages.to_a,
                action: normalize_url( request.url ),
                inputs: params.keys
            )
        end

        return if !f
        f.update( params )
    end

    # Goes through the logged pages and returns all forms which contain
    # password fields
    #
    # @return   [Array<Arachni::Element::Form>]
    def forms_with_password
        @pages_mutex.synchronize do
            @pages.map { |p| p.forms.select { |f| f.requires_password? } }.flatten
        end
    end

    def prepare_pages_for_inspection
        @pages_mutex.synchronize do
            (@pages.map do |p|
                next if !p.text?
                p = p.dup

                %w(links forms cookies jsons xmls).each do |type|
                    p.send(
                        "#{type}=",
                        p.send(type).reject { |e| e.inputs.empty? }
                    )
                end

                if !(p.forms.any? || p.links.any? || p.cookies.any? || p.jsons.any? ||
                    p.xmls.any?)
                    next
                end

                p
            end).compact
        end
    end

    # Called by the proxy for each response.
    def response_handler( request, response )
        return response if response.scope.out? || !response.text? ||
            response.code == 304

        if ignore_responses?
            page = Page.from_data(
                url:      response.url,
                response: response.to_h
            )
        else
            page = response.to_page
        end

        page = update_forms( page, request, response )

        print_info " *  #{page.forms.size} forms"
        print_info " *  #{page.links.size} links"
        print_info " *  #{page.cookies.size} cookies"
        print_info " *  #{page.jsons.size} JSON"
        print_info " *  #{page.xmls.size} XML"

        @pages_mutex.synchronize do
            @pages << page.dup
        end
    end

    def update_forms( page, request, response )
        if (json = Arachni::Element::JSON.from_request( response.url, request ))
            page.jsons |= [json]
            return page
        end

        if (xml = Arachni::Element::XML.from_request( response.url, request ))
            page.xmls |= [xml]
            return page
        end

        page.forms |= [Form.new(
            url:    response.url,
            action: response.url,
            method: request.method,
            inputs: request_parse_body( request.body.to_s )
        )]
        page

    rescue => e
        ap e
        ap e.backtrace
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
    rescue => e
        ap e
        ap e.backtrace
    end

    def ignore_responses?
        @options[:ignore_responses]
    end

    def system_url?( url )
        url.start_with? BASE_URL
    end

    def shutdown?( url )
        url.to_s.start_with? url_for( :shutdown )
    end

    def set_response_body( res, body )
        res.body = body
        res.headers['content-length'] = res.body.size.to_s
        res.headers['content-type'] = 'text/html' if body =~ /<(\s)*html(\s*)(.*?)>/i
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

**MANAGEMENT**

* [Control panel](http://arachni.proxy/panel)
* [Shutdown URL](http://arachni.proxy/shutdown)

_The above URLs will only work from a browser configured to use the proxy._

**SSL**

When browsing HTTPS sites, please accept the Arachni SSL certificate or install
the CA certificate manually from:

    %s

**INFO**

To skip crawling and only audit elements discovered by using the proxy
set the scope page-limit option to '0'.

**NOTICE**

The `session_token` will be looked for in a cookie named
`arachni.proxy.session_token`, so if you choose to use a token to restrict
access to the proxy and need to pass traffic through the proxy programmatically
please configure your HTTP client with a cookie named `arachni.proxy.session_token`
with the value of the 'session_token' option.

**WARNING**

The `session_token` option is not a way to secure usage of this proxy but rather
a way to restrict usage enough to avoid users unwittingly interfering with each
others' sessions.
} % Arachni::HTTP::ProxyServer::SSLInterceptor::CA_CERTIFICATE,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.4',
            options:     [
                Options::Port.new( :port,
                    description: 'Port to bind to.',
                    default:     8282
                ),
                Options::Address.new( :bind_address,
                    description: 'IP address to bind to.',
                    # Don't use 0.0.0.0, it breaks SSL interception on MS Windows.
                    default:     '127.0.0.1'
                ),
                Options::Bool.new( :ignore_responses,
                    description: 'Forces the proxy to only extract vector '+
                        'information from observed HTTP requests and not analyze responses.',
                    default: false
                ),
                Options::String.new( :session_token,
                    description: 'A session token to demand from users before allowing them to use the proxy.'
                ),
                Options::Int.new( :timeout,
                    description: 'How long to wait for a request to complete, in milliseconds.',
                    default:     20000
                )
            ]
        }
    end

end
