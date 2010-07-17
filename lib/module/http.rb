=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

#
# Arachni::HTTP class<br/>
# Provides a simple HTTP interface for modules
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class HTTP

    include Arachni::UI::Output
    
    #
    # The url of the session
    #
    # @return [URI]
    #
    attr_reader :url
    
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
        @url = parse_url( url)

        @opts = Hash.new

        @opts = @opts.merge( opts)

        # create a new HTTP session
        refresh( )
        
        @init_headers = Hash.new
        # TODO: remove global vars
        @init_headers['user-agent'] = $runtime_args[:user_agent]
        @init_headers['cookie'] = ''
#        @init_headers = {}
    end

    #
    # Gets a URL passing the provided variables
    #
    # @param  [URI]  url  URL to get
    # @param  [Array<Hash<String, String>>] url_vars array of name=>value pairs
    #
    # @return [HTTP::Response]
    #
    def get( url, url_vars )
        url = parse_url( url )
        
        begin
            @session.get( url.path +  a_to_s( url_vars ), @init_headers )

        # catch the time-out and refresh
        rescue Timeout::Error => e
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
            print_error( 'Error: ' + e.to_s + " in URL " + url.to_s )
            print_debug( 'Exception: ' +  e.inspect )
            print_debug( 'Backtrace: ' +  e.backtrace.join( "\n" ) )
            print_debug( '@ ' +  __FILE__ + ':' + __LINE__.to_s )
            print_debug( 'HTTP session:' )
            print_debug_pp( @session )
            print_error( 'Proceeding anyway... ' )
        end
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

        #    url = parse_url( url )

        req = Net::HTTP::Post.new( url, @init_headers )
        req.set_form_data( form_vars )

        begin
            res = @session.request( req )
            return res
            
        # catch the time-out and refresh
        rescue Timeout::Error => e
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
        # just print what went wrong with some debugging and then move on
        rescue Exception => e
            print_error( 'Error: ' + e.to_s + " in URL " + url.to_s )
            print_debug( 'Exception: ' +  e.inspect )
            print_debug( 'Backtrace: ' +  e.backtrace.join( "\n" ) )
            print_debug( '@ ' +  __FILE__ + ':' + __LINE__.to_s )
            print_debug( 'HTTP session:' )
            print_debug_pp( @session )
            print_error( 'Proceeding anyway... ' )
        end
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

        cookie_vars.each {
            |a_cookie|

            name  =  a_cookie['name']
            value =  a_cookie['value']
            
            # don't audit cookies in the cookie jar                
            if( @cookie_jar && @cookie_jar[name] ) then next end
            
            @init_headers['cookie'] +=  "#{name}=#{value}; "
        }

        begin
            @session.get( @url.path +  a_to_s( url_vars ), @init_headers )
        
        # catch the time-out and refresh
        rescue Timeout::Error => e
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
        # just print what went wrong with some debugging and then move on
        rescue Exception => e
            print_error( 'Error: ' + e.to_s + " in URL " + url.to_s )
            print_debug( 'Exception: ' +  e.inspect )
            print_debug( 'Backtrace: ' +  e.backtrace.join( "\n" ) )
            print_debug( '@ ' +  __FILE__ + ':' + __LINE__.to_s )
            print_debug( 'HTTP session:' )
            print_debug_pp( @session )
            print_error( 'Proceeding anyway... ' )
        end

    end

    def set_cookies( cookie_hash )
        @cookie_jar = cookie_hash.each_pair {
            |name, value|
            @init_headers['cookie'] += "#{name}=#{value};" 
        }
    end
        
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

    private

    #
    # Converts an Array of Hash<String, String> objects
    # to a path URL String with variables
    #
    # @return [String]
    #
    def a_to_s( arr )
        if !arr || arr.length == 0 then return '' end

        str = '?'
        arr.each {
            |pair|
            str += pair[0] +  '=' + pair[1] + '&'
        }
        str
    end
    
    # Creates a new HTTP session
    def refresh( )
        
        session = Net::HTTP.new( @url.host, @url.port,
        @opts[:proxy_addr], @opts[:proxy_port],
        @opts[:proxy_user], @opts[:proxy_pass] )

        if @url.scheme == 'https'
            session.use_ssl = true
            session.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        @session = session.start

    end

end
end
