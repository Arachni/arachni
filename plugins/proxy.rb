=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Passive proxy.
#
# Will gather data based on user actions and exhanged HTTP traffic and push that
# data to the {Framework#page_queue} to be audited.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Proxy < Arachni::Plugin::Base

    SHUTDOWN_URL = 'http://arachni.proxy.shutdown/'

    MSG_SHUTDOWN = 'Shutting down the Arachni proxy plug-in...'

    MSG_DISALOWED = "You can't access this resource via the Arachni " +
                    "proxy plug-in for the following reasons:"

    MSG_NOT_IN_DOMAIN = 'This resource is on a domain or subdomain' +
        ' outside the scope of the audit.'

    MSG_EXCLUDED = 'This resource is matched by an exclude rule.'

    MSG_NOT_INCLUDED = 'This resource is disallowed based on an include rule.'

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options

        # don't let the framework run just yet
        @framework.pause!
    end

    def prepare
        require @framework.opts.dir['plugins'] + '/proxy/server.rb'

        # we'll need this to parse server responses into Arachni::Parser::Page objects
        @parser = Arachni::Parser.new( @framework.opts )

        @server = Server.new(
            :BindAddress    => @options['bind_address'],
            :Port           => @options['port'],
            :ProxyVia       => false,
            :ProxyContentHandler => method( :handler ),
            :ProxyURITest   => method( :allowed? ),
            :AccessLog      => [],
            :Logger         => WEBrick::Log::new( "/dev/null", 7 )
        )
    end

    def run( )
        print_status( "Listening on: " +
            "http://#{@server[:BindAddress]}:#{@server[:Port]}" )

        print_status( "Shutdown URL: #{SHUTDOWN_URL}" )
        @server.start
    end

    #
    # Called by the proxy to process each page
    #
    def handler( req, res )

        if( res.header['content-encoding'] == 'gzip' )
            res.header.delete( 'content-encoding' )
            res.body = Zlib::GzipReader.new( StringIO.new( res.body ) ).read
        end

        headers = {}
        headers.merge( res.header.dup )     if res.header
        headers['set-cookie'] = res.cookies if !res.cookies.empty?

        page = @parser.run( req.unparsed_uri, res.body, headers )

        page = update_forms( page, req ) if req.body

        print_info " *  #{page.forms.size} forms"
        print_info " *  #{page.links.size} links"
        print_info " *  #{page.cookies.size} cookies"

        @framework.page_queue << page.dup

        return res
    end

    def update_forms( page, req )
        params = {}

        URI.decode( req.body ).split( '&' ).each {
            |param|
            k,v = param.split( '=', 2 )
            params[k] = v
        }

        raw = {
            'attrs' => {
                'action' => req.unparsed_uri,
                'method' => req.request_method,
            }
        }

        form = ::Arachni::Parser::Element::Form.new( req.unparsed_uri, raw )
        form.auditable = params

        page.forms << form

        return page
    end

    #
    # Checks if the URL is allowed.
    #
    # URLs outside the scope of the scan are not allowed.
    #
    def allowed?( uri )

        url = URI( uri )

        print_status( 'Requesting: ' + uri )

        reasons = []

        if shutdown?( url )
            print_status( 'Shutting down...' )
            @server.shutdown
            reasons << MSG_SHUTDOWN
            return reasons
        end

        @parser.url = @framework.opts.url

        reasons << MSG_NOT_IN_DOMAIN if !@parser.in_domain?( url )
        reasons << MSG_EXCLUDED      if @parser.exclude?( url )
        reasons << MSG_NOT_INCLUDED  if !@parser.include?( url )

        if !reasons.empty?
            print_info( "#{MSG_DISALOWED}" )
            reasons.each{ |msg| print_info " *  #{msg}" }
            reasons << MSG_DISALOWED
        end

        return reasons
    end

    def shutdown?( url )
        return url.to_s == SHUTDOWN_URL
    end

    def clean_up
        @framework.resume!
    end

    def self.info
        {
            :name           => 'Proxy',
            :description    => %q{Gathers data based on user actions and exhanged HTTP
                traffic and pushes that data to the framework's page-queue to be audited.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPort.new( 'port', [ false, 'Port to bind to.', 8282 ] ),
                Arachni::OptAddress.new( 'bind_address', [ false, 'IP address to bind to.', '0.0.0.0' ] )
            ]
        }
    end

end

end
end
