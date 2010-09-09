=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
require Options.instance.dir['pwd'] + '../typhoeus/lib/typhoeus'

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
# @version: 0.2
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
        
        req_limit = Options.instance.http_req_limit
        @hydra = Typhoeus::Hydra.new( :max_concurrency => req_limit )
        @hydra.disable_memoization
        
        # create a new HTTP session
        refresh( )
        
        @trainers = []
        
        @init_headers = Hash.new
        @init_headers['user-agent'] = Options.instance.user_agent
        @init_headers['cookie']     = ''
        
        @__not_found  = nil

    end
    
    def run
      @hydra.run
    end
    
    def queue( req )
        @hydra.queue( req )
            
        req.on_complete {
            |res|
                
            # handle redirections
            if( ( redir = redirect?( res.dup ) ).is_a?( String ) )
                res2 = Typhoeus::Request.get( redir )
                train( res2, redir )
            else
                train( res )
            end
        }
    end

    #
    # Gets a URL passing the provided variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] params array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def get( url, params = {}, redirect = false )

        params = { } if !params
        params = params.merge( { '__arachni__' => '' } ) 
        #
        # the exception jail function wraps the block passed to it
        # in exception handling and runs it
        #
        # how cool is Ruby? Seriously....
        #
        exception_jail {

            req = Typhoeus::Request.new( url,
                :headers       => @init_headers.dup,
                :user_agent    => @init_headers['user-agent'],
                :follow_location => false,
                :params        => params )
            
            queue( req )
            
            return req
        }
        
    end

    #
    # Posts a form to a URL with the provided variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] params array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def post( url, params = { } )

        exception_jail {
            
            req = Typhoeus::Request.new( url,
                :method        => :post,
                :headers       => @init_headers.dup,
                :user_agent    => @init_headers['user-agent'],
                :follow_location => false,
                :params        => params )

            queue( req )
            return req
        }
    end

    #
    # Gets a url with cookies and url variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] cookies array of name=>value pairs
    # @param  [Array<Hash<String, String>>] params  array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def cookie( url, cookies, params = nil)

        jar = parse_cookie_str( @init_headers['cookie'] )
        
        cookies.reject! {
            |cookie|
            Options.instance.exclude_cookies.include?( cookie['name'] )
        }
        
        cookies = jar.merge( cookies )
        
        # wrap the code in exception handling
        exception_jail {
            req = Typhoeus::Request.new( url,
                :headers       => { 'cookie' => get_cookies_str( cookies ) },
                :user_agent    => @init_headers['user-agent'],
                :params        => params )
            
            
            queue( req )
            return req
        }
    end

    #
    # Gets a url with optional url variables and modified headers
    #
    # @param  [URI]  url  URL to get
    # @param  [Hash<String, String>] headers hash of name=>value pairs
    # @param  [Array<Hash<String, String>>] params array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def header( url, headers, params = nil )

        # wrap the code in exception handling
        exception_jail {
            
            orig_headers  = @init_headers.clone
            @init_headers = @init_headers.merge( headers )
            
            req = Typhoeus::Request.new( url,
                :headers       => @init_headers.dup,
                :user_agent    => @init_headers['user-agent'],
                :params        => params )
            
            @init_headers = orig_headers.clone
            
            queue( req )
            
            return req
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
    
    #
    # Gets cookies as a string for the HTTP session
    #
    # @param    [Hash]  cookie_hash  name=>value pair cookies
    #
    # @return    [void]
    #
    def get_cookies_str( cookie_hash )
        str = ''
        cookie_hash.each_pair {
            |name, value|
            str += "#{name}=#{value};" 
        }
        return str
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
    # Checks whether or not the provided HTML code is a custom 404 page
    #
    # @param  [String]  html  the HTML code to check
    #
    # @param  [Bool]
    #
    def custom_404?( html )
        
        if( !@__not_found )
            
            path = Module::Utilities.get_path( @url.to_s )
            
            # force a 404 and grab the html body
            force_404    = path + Digest::SHA1.hexdigest( rand( 9999999 ).to_s ) + '/'
            @__not_found = Typhoeus::Request.get( force_404 ).body
            
            # force another 404 and grab the html body
            force_404   = path + Digest::SHA1.hexdigest( rand( 9999999 ).to_s ) + '/'
            not_found2  = Typhoeus::Request.get( force_404 ).body
            
            #
            # some websites may have dynamic 404 pages or simply include
            # the query that caused the 404 in the 404 page causing the 404 pages to change.
            #
            # so get rid of the differences between the 2 404s (if there are any)
            # and store what *doesn't* change into @__404
            #
            @__404 = Arachni::Module::Utilities.rdiff( @__not_found, not_found2 )
        end
        
        #
        # get the rdiff between 'html' and an actual 404
        #
        # if this rdiff matches the rdiff in @__404 then by extension
        # the 'html' is a 404
        # 
        return Arachni::Module::Utilities.rdiff( @__not_found, html ) == @__404
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
        if loc = res.headers_hash['Location']
            return loc
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

        if @url.scheme == 'https'
        end

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
