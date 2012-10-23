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

require 'erb'
require 'ostruct'

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

    BASEDIR  = "#{File.dirname( __FILE__ )}/proxy/"
    BASE_URL = 'http://arachni.proxy.'

    class TemplateScope
        include Arachni::Utilities

        PANEL_BASEDIR  = "#{Arachni::Plugins::Proxy::BASEDIR}panel/"
        PANEL_TEMPLATE = "#{PANEL_BASEDIR}panel.html.erb"
        PANEL_URL      = "#{Arachni::Plugins::Proxy::BASE_URL}panel/"

        def initialize( params = {} )
            update( params )
        end

        def self.new( *args )
            @self ||= super( *args )
        end

        def self.get
            new
        end

        def root_url
            PANEL_URL
        end

        def js_url
            "#{root_url}js/"
        end

        def css_url
            "#{root_url}css/"
        end

        def img_url
            "#{root_url}img/"
        end

        def inspect_url
            "#{root_url}inspect"
        end

        def shutdown_url
            url_for :shutdown
        end

        def url_for( *args )
            Arachni::Plugins::Proxy.url_for( *args )
        end

        def update( params )
            params.each { |name, value| set( name, value ) }
            self
        end

        def set( name, value )
            self.class.send( :attr_accessor, name )
            instance_variable_set( "@#{name.to_s}", value )
            self
        end

        def content_for?( ivar )
            !!instance_variable_get( "@#{ivar.to_s}" )
        end

        def content_for( name, value = :nil )
            if value == :nil
                instance_variable_get( "@#{name.to_s}" )
            else
                set( name, html_encode( value.to_s ) )
                nil
            end
        end

        def erb( tpl, params = {} )
            params = params.dup
            params[:params] ||= {}

            with_layout = true
            with_layout = !!params.delete( :layout ) if params.include?( :layout )

            update( params )

            tpl = tpl.to_s + '.html.erb' if tpl.is_a?( Symbol )

            path = File.exist?( tpl ) ? tpl : PANEL_BASEDIR + tpl

            evaled = ERB.new( IO.read( path ) ).result( get_binding )
            with_layout ? layout { evaled } : evaled
        end

        def render( tpl, opts )
            erb tpl, opts.merge( layout: false )
        end

        def layout
            ERB.new( IO.read( PANEL_BASEDIR + 'layout.html.erb' ) ).result( binding )
        end

        def panel
            erb :panel
        end

        def get_binding
            binding
        end

        def clear
            instance_variables.each { |v| instance_variable_set( v, nil ) }
        end
    end


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

        require "#{File.dirname( __FILE__ )}/proxy/server"

        @server = Server.new(
             BindAddress:         options['bind_address'],
             Port:                options['port'],
             ProxyVia:            false,
             ProxyContentHandler: method( :response_handler ),
             ProxyRequestHandler: method( :request_handler ),
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

    def request_handler( req, res )
        url    = req.request_uri.to_s
        params = parse_request_body( req.body.to_s ).merge( parse_query( url ) ) || {}

        TemplateScope.get.clear
        TemplateScope.get.set :page_count, prepare_pages_for_inspection.size
        TemplateScope.get.set :recording, recording?

        print_status "Requesting #{url}"

        if shutdown?( url )
            print_status 'Shutting down...'
            set_response_body( res, erb( :shutdown_message ) )
            @server.shutdown
            return
        end

        reasons = []
        if !system_url?( url )
            reasons << MSG_NOT_IN_DOMAIN if !path_in_domain?( url )
            reasons << MSG_EXCLUDED      if exclude_path?( url )
            reasons << MSG_NOT_INCLUDED  if !include_path?( url )
        end

        if reasons.any?
            print_info MSG_DISALLOWED
            reasons.each { |reason| print_info "  * #{reason}" }

            # forbidden
            res.status = 403
            set_response_body( res, erb( '403_forbidden'.to_sym, { reasons: reasons } ) )
            return false
        end

        @login_sequence << req if recording?

        if url.start_with? url_for( :panel )
            body =  case res.request_uri.path
                        when '/'
                            erb :panel

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
                            begin
                                IO.read TemplateScope::PANEL_BASEDIR + res.request_uri.path
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
        return res if res.request_method.to_s.downcase == 'connect'

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
        return res if !res.header['content-type'].to_s.start_with?( 'text/html' )

        body_tag = res.body.match( /<(\s*)body(.*)>/i )
        res.body.gsub!( body_tag.to_s, "#{body_tag}#{panel_iframe}" )
        res.header['content-length'] = res.body.size.to_s
        res
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

    def self.url_for( type )
        {
            shutdown: "#{BASE_URL}shutdown",
            panel:    "#{BASE_URL}panel",
            inspect:  "#{BASE_URL}panel/inspect",
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

                To skip crawling and only audit elements discovered by using the proxy
                set '--link-count=0'.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            options:     [
                 Options::Port.new( 'port', [false, 'Port to bind to.', 8282] ),
                 Options::Address.new( 'bind_address', [false, 'IP address to bind to.', '0.0.0.0'] ),
                 Options::Int.new( 'timeout', [false, 'How long to wait for a request to complete, in milliseconds.', 20000] )
             ]
        }
    end

end
