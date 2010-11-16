=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'webrick/httpproxy'
require 'stringio'
require 'zlib'
require 'open-uri'

module WEBrick

    #
    # We add our own type of WEBrick::HTTPProxyServer class that supports
    # notifications when the user tries to access a resource irrelevant
    # to the scan and does not restrict header exchange.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class ArachniProxyServer < HTTPProxyServer

        def choose_header(src, dst)
            connections = split_field(src['connection'])
            src.each{|key, value|
                key = key.downcase
                if HopByHop.member?(key)          || # RFC2616: 13.5.1
                   connections.member?(key)       || # RFC2616: 14.10
                   # ShouldNotTransfer.member?(key)    # pragmatics
                  @logger.debug("choose_header: `#{key}: #{value}'")
                  next
                end
            dst[key] = value
          }
        end

        def service( req, res )
            exclude_reasons = @config[:ProxyURITest].call( req.unparsed_uri )

            if( exclude_reasons.empty? )
                super( req, res )
            else
                notify( exclude_reasons, req, res )
            end
        end

        def notify( reasons, req, res )
            res.header['content-type'] = 'text/plain'
            res.header.delete( 'content-encoding' )

            res.body << reasons.map{ |msg| " *  #{msg}" }.join( "\n" )
        end
    end

end

module Arachni
module Plugins

class Proxy

#
# This little piece of wonder monitors HTTP traffic, extracts
# auditable elements and pushes them in the {Framework#page_queue} to be audited.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class TrainerProxy

    include Arachni::Module::Output


    SHUTDOWN_URL = 'http://arachni.plugin.terminate/'

    MSG_SHUTDOWN = 'Shutting down the Arachni proxy plug-in...'

    MSG_DISALOWED = "You can't access this resource via the Arachni " +
                    "proxy plug-in for the following reasons:"

    MSG_NOT_IN_DOMAIN = 'This resource is on a domain or subdomain' +
        ' outside the scope of the audit.'

    MSG_EXCLUDED = 'This resource is matched by an exclude rule.'

    MSG_NOT_INCLUDED = 'This resource is disallowed based on an include rule.'

    #
    # @param    [Framework]    framework    the framework instance
    # @param    [Hash]         opts         plugin options, check the options
    #                                       in Proxy's self.info
    #
    def initialize( framework, opts = {} )
        @framework   = framework

        # we'll need this to parse server
        # responses into Arachni::Parser::Page objects
        @parser      = Arachni::Parser.new( @framework.opts )

        @server = WEBrick::ArachniProxyServer.new(
            :BindAddress    => opts[:bind_address] || '0.0.0.0',
            :Port           => opts[:port] || 8282,
            :ProxyVia       => false,
            :ProxyContentHandler => method( :handler ),
            :ProxyURITest   => method( :allowed? ),
            :AccessLog      => [],
            :Logger         => WEBrick::Log::new( "/dev/null", 7 )
        )

        print_status( "Listening on: " +
            "http://#{@server[:BindAddress]}:#{@server[:Port]}" )

        print_status( "Shutdown URL: #{SHUTDOWN_URL}" )

    end

    #
    # Called by the proxy to process each page
    #
    def handler( req, res )

        if( 'gzip' == res.header['content-encoding'] )
            res.header.delete( 'content-encoding' )
            res.body = Zlib::GzipReader.new( StringIO.new( res.body ) ).read
        end

        headers = {}
        headers.merge( res.header.dup )     if res.header
        headers['set-cookie'] = res.cookies if !res.cookies.empty?

        page = @parser.run( req.unparsed_uri, res.body, headers )

        print_info " *  #{page.forms.size} forms"
        print_info " *  #{page.links.size} links"
        print_info " *  #{page.cookies.size} cookies"

        @framework.page_queue << page

        return res
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

        if terminate?( url )
            print_status( 'Shutting down...' )
            stop
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

    def terminate?( url )
        return url.to_s == SHUTDOWN_URL
    end

    def start
        @server.start
    end

    def stop
        @server.shutdown
    end

    def self.info
        { :name => 'TrainerProxy' }
    end
end

end
end
end

