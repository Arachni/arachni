=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module

#
# Arachni::Module::HTTP class
#
# Provides a simple HTTP interface for modules.
#
# === Exceptions
# Any exceptions or session corruption is handled by the class.<br/>
# Some are ignored, on others the HTTP session is refreshed.<br/>
# Point is, you don't need to worry about it.
#
# @author: Anastasios "Zapotek" Laskos 
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class HTTP

    include Arachni::UI::Output
    
    #
    # The url of the session
    #
    # @return [URI]
    #
    attr_reader :url
    
    #
    # The headers with which the HTTP client is initialized<br/>
    # This is always kept updated.
    # 
    # @return    [Hash]
    #
    attr_reader :init_headers
    
    #
    # The user supplied cookie jar
    #
    # @return    [Hash]
    #
    attr_reader :cookie_jar
    
    #
    # The HTTP session
    #
    # @return [Net::HTTP]
    #
    attr_reader :session

    #
    # Initializes the HTTP session given a start URL respecting
    # system wide settings for HTTP basic auth and proxy
    #
    # @param [String] url start URL
    #
    # @return [Net::HTTP]
    #
    def initialize( url, opts = {} )
        @url = parse_url( url )

        @opts = Hash.new

        @opts = @opts.merge( opts )

        # create a new HTTP session
        refresh( )
        
        @trainers = []
        
        @init_headers = Hash.new
        @init_headers['user-agent'] = Options.instance.user_agent
        @init_headers['cookie']     = ''
    end

    #
    # Gets a URL passing the provided variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] url_vars array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def get( url, url_vars = nil, redirect = false )
        url = parse_url( url )

        #
        # the exception jail function wraps the block passed to it
        # in exception handling and runs it
        #
        # how cool is Ruby? Seriously....
        #
        exception_jail {

            if( url.query && url.query.size > 0 )
                query = '?' + url.query
                append = true
            else
                query = ''
                append = false
            end
            
            if( redirect )
                full_url = url.path + query
            else
                full_url = url.path + URI.encode( query ) + a_to_s( url_vars, append )
            end
             
            res = @session.get( full_url, @init_headers )
            
            # handle redirections
            if( ( redir = redirect?( res ) ).is_a?( String ) )
                res = get( redir, nil, true )
                train( res, redir )
            else
                train( res )
            end
            
            return res
        }
        
    end

    #
    # Posts a form to a URL with the provided variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] form_vars array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def post( url, form_vars )

        req = Net::HTTP::Post.new( url, @init_headers )
        req.set_form_data( form_vars )

        exception_jail {
            res = @session.request( req )
            
            # handle redirections
            if( ( redir = redirect?( res ) ).is_a?( String ) )
                res =  get( redir, nil, true )
                train( res, redir )
            else
                train( res )
            end

            return res
        }
    end

    #
    # Gets a url with cookies and url variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] cookie_vars array of name=>value pairs
    # @param  [Array<Hash<String, String>>] url_vars array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def cookie( url, cookie_vars, url_vars = nil)

        orig_cookiejar = @init_headers['cookie'].clone 
        
        cookies = ''
        parse_cookie_str( orig_cookiejar ).merge( cookie_vars ).each_pair {
            |name, value|

            # don't audit cookies in the cookie jar                
#            if( !Options.instance.audit_cookie_jar] &&
#                @cookie_jar && @cookie_jar[name] ) then next end
            
            cookies +=  "#{name}=#{value};"
        }
        
        @init_headers['cookie'] = cookies

        # wrap the code in exception handling
        exception_jail {
            url = parse_url( url )
            
            if( url.query && url.query.size > 0 )
                query = '?' + url.query
                append = true
            else
                query = ''
                append = false
            end
            
            full_url = url.path + URI.encode( query ) + a_to_s( url_vars, append )
                        
            res = @session.get( full_url, @init_headers )
            @init_headers['cookie'] = orig_cookiejar.clone
            train( res )
            return res
        }
    end

    #
    # Gets a url with optional url variables and modified headers
    #
    # @param  [URI]  url  URL to get
    # @param  [Hash<String, String>] headers hash of name=>value pairs
    # @param  [Array<Hash<String, String>>] url_vars array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def header( url, headers, url_vars = nil)

        # wrap the code in exception handling
        exception_jail {
            url = parse_url( url )
            
            if( url.query && url.query.size > 0 )
                query = '?' + url.query
                append = true
            else
                query = ''
                append = false
            end
            
            full_url = url.path + URI.encode( query ) + a_to_s( url_vars, append )
            
            orig_headers  = @init_headers.clone
            @init_headers = @init_headers.merge( headers )
            
            res = @session.get( full_url, @init_headers )
            
            @init_headers = orig_headers.clone
            train( res )
            return res
        }

    end

    
    #
    # Sets cookies for the HTTP session
    #
    # @param    [Hash]  cookie_hash  name=>value pair cookies
    #
    # @return    [void]
    #
    def set_cookies( cookie_hash )
        @init_headers['cookie'] = ''
        @cookie_jar = cookie_hash.each_pair {
            |name, value|
            @init_headers['cookie'] += "#{name}=#{value};" 
        }
    end
    
    def parse_cookie_str( str )
        cookie_jar = Hash.new
        str.split( ';' ).each {
            |kvp|
            cookie_jar[kvp.split( "=" )[0]] = kvp.split( "=" )[1] 
        }
        return cookie_jar
    end
    
    #
    # Class method
    #
    # Parses netscape HTTP cookie file
    #
    # @param    [String]  cookie_jar  the location of the cookie file
    #
    # @return    [Hash]     cookies in name=>value pairs
    #    
    def HTTP.parse_cookiejar( cookie_jar )
        
        cookies = Hash.new
        
        jar = File.open( cookie_jar, 'r' ) 
        jar.each_line {
            |line|
            
            # skip empty lines
            if (line = line.strip).size == 0 then next end
                
            # skip comment lines
            if line[0] == '#' then next end
                
            cookie_arr = line.split( "\t" )
            
            cookies[cookie_arr[-2]] = cookie_arr[-1]
        }
        
        cookies
    end
    
    #
    # Encodes and parses a URL String
    #
    # @param [String] url URL String
    #
    # @return [URI] URI object
    #
    def parse_url( url )
        URI.parse( URI.encode( url ) )
    end

    #
    # Blocks passed to this method will be passed each HTTP response<br/>
    # and in cases of redirection the new location as well.
    #
    def add_trainer( &block )
        @trainers << block
    end
    
    private
    
    #
    #
    #
    def train( res, url = nil )
        @trainers.each{ |trainer| trainer.call( res, url ) } 
    end
    
    def redirect?( res )
        if res.is_a?( Net::HTTPRedirection )
            return res['location']
        end
        return res
    end

    #
    # Converts an Array of Hash<String, String> objects
    # to a query URL String with variables
    #
    # @param    [Array<Hash>]  arr    
    # @param    [Bool]    append    create a new url query string or
    #                                   a string to be appended to the existing url?
    #
    # @return [String]
    #
    def a_to_s( arr, append = false )
        if !arr || arr.length == 0 then return '' end

        if( append == true )
            str = '&'
        else
            str = '?'
        end
        
        arr.each {
            |pair|
            str += pair[0].to_s +  '=' + URI.escape( pair[1].to_s ) + '&'
        }
        
        # URI.escape() doesn't escape spaces..don't ask me why...
        str.gsub( / /, '+' )
    end
    
    #
    # Creates a new HTTP session<br/>
    # Actually...since keep-alive is on it will either create a new connection
    # or refresh an existing one.
    #
    def refresh( )
        
        opts = Options.instance

        session = Net::HTTP.new( @url.host, @url.port,
            opts.proxy_addr, opts.proxy_port,
            opts.proxy_user, opts.proxy_pass )

        if @url.scheme == 'https'
            session.use_ssl = true
            session.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        @session = session.start

    end
    
    #
    # Wraps the "block" in exception handling code and runs it.
    #
    # @param    [Block]
    #
    def exception_jail( &block )
        
        begin
            block.call

        # catch the time-out and refresh
        rescue Timeout::Error => e
            # inform the user
            print_error( 'Error: ' + e.to_s + " in URL " + url.to_s )
            print_info( 'Refreshing connection...' )
            
            # refresh the connection
            refresh( )
            # try one more time
            retry

        # broken pipe probably
        rescue Errno::EPIPE => e
            # inform the user
            print_error( 'Error: ' + e.to_s + " in URL " + url.to_s )
            print_info( 'Refreshing connection...' )
            
            # refresh the connection
            refresh( )
            # try one more time
            retry
        
        # some other exception
        # just print what went wrong with some debugging info and move on
        rescue Exception => e
            handle_exception( e )
        end
    end
    
    #
    # Handles an exception outputting info about it and the environment<br/>
    # when it occured, depending on the output settings.
    #
    # @param    [Exception]     e
    #
    def handle_exception( e )
        print_error( 'Error: ' + e.to_s + " in URL " + url.to_s )
        print_debug( 'Exception: ' +  e.inspect )
        print_debug( 'Backtrace: ' )
        print_debug_backtrace( e )
        print_debug( '@ ' +  __FILE__ + ':' + __LINE__.to_s )
        print_debug( 'HTTP session:' )
        print_debug_pp( @session )
#        print_debug( YAML::dump( @session ) )
        print_error( 'Proceeding anyway... ' )
    end
       

end
end
end
