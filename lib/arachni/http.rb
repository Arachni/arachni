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

require 'typhoeus'

module Arachni
require Options.instance.dir['lib'] + 'ruby/webrick'
require Options.instance.dir['lib'] + 'typhoeus/hydra'
require Options.instance.dir['lib'] + 'typhoeus/request'
require Options.instance.dir['lib'] + 'typhoeus/response'
require Options.instance.dir['lib'] + 'module/utilities'
require Options.instance.dir['lib'] + 'module/trainer'
require Options.instance.dir['lib'] + 'mixins/observable'

#
# Arachni::Module::HTTP class
#
# Provides a simple, high-performance and thread-safe HTTP interface to modules.
#
# All requests are run Async (compliments of Typhoeus)
# providing great speed and performance.
#
# === Exceptions
# Any exceptions or session corruption is handled by the class.<br/>
# Some are ignored, on others the HTTP session is refreshed.<br/>
# Point is, you don't need to worry about it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HTTP

    include Arachni::UI::Output
    include Singleton
    include Arachni::Module::Utilities
    include Arachni::Mixins::Observable

    #
    # @return [URI]
    #
    attr_reader :last_url

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

    attr_reader :request_count
    attr_reader :response_count

    attr_reader :time_out_count

    attr_reader :curr_res_time
    attr_reader :curr_res_cnt

    attr_reader :trainer

    def initialize
        reset!
    end

    def reset!
        opts = Options.instance

        req_limit = opts.http_req_limit

        hydra_opts = {
            :max_concurrency               => req_limit,
            :method                        => :auto
        }

        if opts.url
            hydra_opts.merge!(
                :username => opts.url.user,
                :password  => opts.url.password,
            )
        end

        @hydra      = Typhoeus::Hydra.new( hydra_opts )
        @hydra_sync = Typhoeus::Hydra.new( hydra_opts.merge( :max_concurrency => 1 ) )

        @hydra.disable_memoization
        @hydra_sync.disable_memoization

        @trainer = Arachni::Module::Trainer.new( opts )

        @init_headers = {
            'cookie' => '',
            'From'   => opts.authed_by || '',
            'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'User-Agent'    => opts.user_agent
        }.merge( opts.custom_headers )

        cookies = {}
        cookies.merge!( self.class.parse_cookiejar( opts.cookie_jar ) ) if opts.cookie_jar
        cookies.merge!( opts.cookies ) if opts.cookies

        set_cookies( cookies ) if !cookies.empty?

        proxy_opts = {}
        proxy_opts = {
            :proxy           => "#{opts.proxy_addr}:#{opts.proxy_port}",
            :proxy_username  => opts.proxy_user,
            :proxy_password  => opts.proxy_pass,
            :proxy_type      => opts.proxy_type
        } if opts.proxy_addr

        @opts = {
            :follow_location => false,
            :max_redirects  =>  opts.redirect_limit,
            :disable_ssl_peer_verification => true,
            :timeout         => 50000
        }.merge( proxy_opts )

        @request_count  = 0
        @response_count = 0
        @time_out_count = 0

        # we'll use it to identify our requests
        @rand_seed = seed( )

        @curr_res_time = 0
        @curr_res_cnt  = 0

        @after_run = []
    end

    #
    # Runs Hydra (all the asynchronous queued HTTP requests)
    #
    # Should only be called by the framework
    # after all module threads have been joined!
    #
    def run
        exception_jail {
            @hydra.run

            @after_run.each {
                |block|
                block.call
            }
            @after_run.clear

            call_after_run_persistent( )

            @curr_res_time = 0
            @curr_res_cnt  = 0
        }
    end

    def fire_and_forget
        exception_jail {
            @hydra.fire_and_forget
        }
    end

    def abort
        exception_jail {
            @hydra.abort
        }
    end

    def average_res_time
        return 0 if @curr_res_cnt == 0
        return @curr_res_time / @curr_res_cnt
    end

    def max_concurrency!( max_concurrency )
        @hydra.max_concurrency = max_concurrency
    end

    def max_concurrency
        @hydra.max_concurrency
    end

    #
    # Queues a Tyhpoeus::Request and calls the following callbacks:
    # * on_queue() -- intersects a queued request and gets passed the original
    #   and the async method. If the block returns one or more request
    #   objects these will be queued instead of the original request.
    # * on_complete() -- calls the block with the each requests as it arrives.
    #
    # @param  [Tyhpoeus::Request]  req  the request to queue
    # @param  [Bool]  async  run request async?
    #
    def queue( req, async = true )
        requests = call_on_queue( req, async )
        requests ||= req

        [ requests ].flatten.reject { |p| !p.is_a?( Typhoeus::Request ) }.each {
            |request|
            forward_request( request, async )
        }
    end

    #
    # Gets called each time a hydra run finishes
    #
    def after_run( &block )
        @after_run << block
    end

    #
    # Makes a generic request
    #
    # @param  [URI]  url
    # @param  [Hash] opts
    #
    # @return [Typhoeus::Request]
    #
    def request( url, opts )
        params    = opts[:params]    || {}
        remove_id = opts[:remove_id]
        train     = opts[:train]
        timeout   = opts[:timeout]
        cookies   = opts[:cookies]

        update_cookies   = opts[:update_cookies]

        async     = opts[:async]
        async     = true if async == nil

        follow_location    = opts[:follow_location]    || false

        headers   = opts[:headers]   || {}

        #
        # the exception jail function wraps the block passed to it
        # in exception handling and runs it
        #
        # how cool is Ruby? Seriously....
        #
        exception_jail {

            headers       = @init_headers.merge( headers )
            headers['cookie'] = get_cookies_str( cookies, false ) if cookies

            params = params.merge( { @rand_seed => '' } ) if !remove_id

            #
            # There are cases where the url already has a query and we also have
            # some params to work with. Some webapp frameworks will break
            # or get confused...plus the url will not be RFC compliant.
            #
            # Thus we need to merge the provided params with the
            # params of the url query and remove the latter from the url.
            #
            cparams = params.dup
            curl    = normalize_url( url.dup )

            if opts[:method] != :post
                begin
                    cparams = q_to_h( curl ).merge( cparams )
                    curl.gsub!( "?#{URI(curl).query}", '' ) if URI(curl).query
                rescue
                    return
                end
            end

            opts = {
                :headers       => headers,
                :params        => cparams.empty? ? nil : cparams,
                :method        => opts[:method].nil? ? :get : opts[:method]
            }.merge( @opts )

            opts[:follow_location] = follow_location if follow_location

            opts[:timeout] = timeout if timeout

            req = Typhoeus::Request.new( curl, opts )
            req.train! if train
            req.update_cookies! if update_cookies

            queue( req, async )
            return req
        }
    end

    #
    # Gets a URL passing the provided query parameters
    #
    # @param  [URI]  url     URL to GET
    # @param  [Hash] opts    request options
    #                         * :params  => request parameters || {}
    #                         * :train   => force Arachni to analyze the HTML code || false
    #                         * :async   => make the request async? || true
    #                         * :headers => HTTP request headers  || {}
    #                         * :follow_location => follow redirects || false
    #
    # @return [Typhoeus::Request]
    #
    def get( url, opts = { } )
        request( url, opts )
    end

    #
    # Posts a form to a URL with the provided query parameters
    #
    # @param  [URI]   url     URL to POST
    # @param  [Hash]  opts    request options
    #                          * :params  => request parameters || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #                          * :headers => HTTP request headers  || {}
    #
    # @return [Typhoeus::Request]
    #
    def post( url, opts = { } )
        request( url, opts.merge( :method => :post ) )
    end

    #
    # Sends an HTTP TRACE request to "url".
    #
    # @param  [URI]   url     URL to POST
    # @param  [Hash]  opts    request options
    #                          * :params  => request parameters || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #                          * :headers => HTTP request headers  || {}
    #
    # @return [Typhoeus::Request]
    #
    def trace( url, opts = { } )
        request( url, opts.merge( :method => :trace ) )
    end


    #
    # Gets a url with cookies and url variables
    #
    # @param  [URI]   url      URL to GET
    # @param  [Hash]  opts    request options
    #                          * :params  => cookies || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #                          * :headers => HTTP request headers  || {}
    #
    # @return [Typhoeus::Request]
    #
    def cookie( url, opts = { } )
        opts[:cookies] = (opts[:params] || {}).dup
        opts[:params] = nil
        request( url, opts )
    end

    #
    # Gets a url with optional url variables and modified headers
    #
    # @param  [URI]   url      URL to GET
    # @param  [Hash]  opts    request options
    #                          * :params  => headers || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #
    # @return [Typhoeus::Request]
    #
    def header( url, opts = { } )

        headers   = opts[:params] || {}

        orig_headers      = @init_headers.clone
        opts[:headers]    = @init_headers = @init_headers.merge( headers )
        opts[:user_agent] = @init_headers['User-Agent']

        opts[:params] = nil

        req = request( url, opts )

        @init_headers = orig_headers.clone
        return req
    end

    def q_to_h( url )
        params = {}

        begin
            query = URI( url.to_s ).query
            return params if !query

            query.split( '&' ).each {
                |param|
                k,v = param.split( '=', 2 )
                params[k] = v
            }
        rescue
        end

        return params
    end

    def current_cookies
        parse_cookie_str( @init_headers['cookie'] )
    end

    def update_cookies( cookies )
        set_cookies( current_cookies.merge( cookies ) )
    end

    #
    # Sets cookies for the HTTP session
    #
    # @param    [Hash]  cookies  name=>value pairs
    #
    # @return   [void]
    #
    def set_cookies( cookies )
        @init_headers['cookie'] = ''
        @cookie_jar = cookies.each_pair {
            |name, value|
            @init_headers['cookie'] += "#{name}=#{value};"
        }
    end

    def parse_and_set_cookies( res )
        cookie_hash = {}

        # extract cookies from the header field
        begin
            [res.headers_hash['Set-Cookie']].flatten.each {
                |set_cookie_str|

                break if !set_cookie_str.is_a?( String )
                cookie_hash.merge!( WEBrick::Cookie.parse_set_cookies(set_cookie_str).inject({}) do |hash, cookie|
                    hash[cookie.name] = cookie.value if !!cookie
                    hash
                end
                )
            }
        rescue Exception => e
            print_debug( e.to_s )
            print_debug_backtrace( e )
        end

        # extract cookies from the META tags
        begin

            # get get the head in order to check if it has an http-equiv for set-cookie
            head = res.body.match( /<head(.*)<\/head>/imx )

            # if it does feed the head to the parser in order to extract the cookies
            if head && head.to_s.substring?( 'set-cookie' )
                Nokogiri::HTML( head.to_s ).search( "//meta[@http-equiv]" ).each {
                    |elem|
                    next if elem['http-equiv'].downcase != 'set-cookie'
                    cookie = WEBrick::Cookie.parse_set_cookies( elem['content'] )
                    cookie_hash[cookie.name] = cookie.value
                }
            end
        rescue Exception => e
            print_debug( e.to_s )
            print_debug_backtrace( e )
        end

        return if cookie_hash.empty?

        # update framework cookies
        Arachni::Options.instance.cookies = cookie_hash

        call_on_new_cookies( cookie_hash, res )

        current = parse_cookie_str( @init_headers['cookie'] )
        set_cookies( current.merge( cookie_hash ) )
    end

    #
    # Returns a hash of cookies as a string (merged with the cookie-jar)
    #
    # @param    [Hash]  cookies  name=>value pairs
    #
    # @return   [string]
    #
    def get_cookies_str( cookies = { }, with_existing = true )

        if with_existing
            jar = parse_cookie_str( @init_headers['cookie'] )
            cookies = jar.merge( cookies )
        end

        str = ''
        cookies.each_pair {
            |name, value|
            value = '' if !value
            val = uri_encode( uri_encode( value ), '+;' )
            str += "#{name}=#{val};"
        }
        return str
    end

    #
    # Converts HTTP cookies from string to Hash
    #
    # @param  [String]  str
    #
    # @return  [Hash]
    #
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
    # Parses netscape HTTP cookie files
    #
    # @param    [String]  cookie_jar  the location of the cookie file
    #
    # @return   [Hash]    cookies     in name=>value pairs
    #
    def self.parse_cookiejar( cookie_jar )

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

    def self.content_type( headers_hash )
        return if !headers_hash.is_a?( Hash )

        headers_hash.each_pair {
            |key, val|
            return val if key.to_s.downcase == 'content-type'
        }

        return
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
    # Checks whether or not the provided response is a custom 404 page
    #
    # @param  [Typhoeus::Response]  res  the response to check
    #
    # @param  [Bool]
    #
    def custom_404?( res, &block )
        precision = 2

        @_404 ||= {}
        path  = get_path( res.effective_url )
        @_404[path] ||= []

        uri = uri_parse( res.effective_url )
        trv_back = File.dirname( uri.path )
        trv_back_url = uri.scheme + '://' +  uri.host + ':' + uri.port.to_s + trv_back
        trv_back_url += '/' if trv_back_url[-1] != '/'

        # 404 probes
        generators = [
            # get a random path with an extension
            proc{ path + random_string + '.' + random_string[0..precision] },

            # get a random path without an extension
            proc{ path + random_string },

            # move up a dir and get a random file
            proc{ trv_back_url + random_string },

            # move up a dir and get a random file with an extension
            proc{ trv_back_url + random_string + '.' + random_string[0..precision] },

            # get a random directory
            proc{ path + random_string + '/' }
        ]

        @_404_gathered ||= Hash.new( false )

        gathered = 0
        body = res.body
        # (precision - 1).times {
            # get( res.effective_url, :remove_id => true ).on_complete {
                # |c_res|
                # body = body.rdiff( c_res.body )
                # gathered += 1
                # if gathered == generators.size * precision + precision - 1
                    # block.call is_404?( path, body )
                # end
            # }
        # }

        if !@_404_gathered[path]
            generators.each.with_index {
                |generator, i|

                @_404[path][i] ||= {}
                precision.times {
                    get( generator.call, :remove_id => true ).on_complete {
                        |c_res|

                        gathered += 1
                        if gathered == generators.size * precision
                            @_404_gathered[path] = true
                            block.call is_404?( path, body )
                        else
                            @_404[path][i]['rdiff_now'] ||= false

                            if !@_404[path][i]['body']
                                @_404[path][i]['body'] = c_res.body
                            else
                                @_404[path][i]['rdiff_now'] = true
                            end

                            if @_404[path][i]['rdiff_now'] && !@_404[path][i]['rdiff']
                                @_404[path][i]['rdiff'] = @_404[path][i]['body'].rdiff( c_res.body )
                            end
                        end
                    }
                }
            }
        else
            block.call is_404?( path, body )
        end
    end

    private

    def forward_request( req, async = true )
        req.id = @request_count

        if( !async )
            @hydra_sync.queue( req )
        else
            @hydra.queue( req )
        end

        @request_count += 1

        print_debug( '------------' )
        print_debug( 'Queued request.' )
        print_debug( 'ID#: ' + req.id.to_s )
        print_debug( 'URL: ' + req.url )
        print_debug( 'Method: ' + req.method.to_s  )
        print_debug( 'Params: ' + req.params.to_s  )
        print_debug( 'Headers: ' + req.headers.to_s  )
        print_debug( 'Train?: ' + req.train?.to_s  )
        print_debug(  '------------' )

        req.on_complete( true ) {
            |res|

            @response_count += 1
            @curr_res_cnt   += 1
            @curr_res_time  += res.start_transfer_time

            call_on_complete( res )

            parse_and_set_cookies( res ) if req.update_cookies?

            print_debug( '------------' )
            print_debug( 'Got response.' )
            print_debug( 'Request ID#: ' + res.request.id.to_s )
            print_debug( 'URL: ' + res.effective_url )
            print_debug( 'Method: ' + res.request.method.to_s  )
            print_debug( 'Params: ' + res.request.params.to_s  )
            print_debug( 'Headers: ' + res.request.headers.to_s  )
            print_debug( 'Train?: ' + res.request.train?.to_s  )
            print_debug( '------------' )

            if res.timed_out?
                # print_error( 'Request timed-out! -- ID# ' + res.request.id.to_s )
                @time_out_count += 1
            end

            if( req.train? )
                # handle redirections
                if( ( redir = redirect?( res.dup ) ).is_a?( String ) )
                    req2 = get( redir, :remove_id => true )
                    req2.on_complete {
                        |res2|
                        @trainer.add_response( res2, true )
                    } if req2
                else
                    @trainer.add_response( res )
                end
            end
        }

        exception_jail {
            @hydra_sync.run if !async
        }
    end

    def is_404?( path, body )
        @_404[path].map {
            |_404|
             _404['body'].rdiff( body ) == _404['rdiff']
        }.include?( true )
    end

    def random_string
        Digest::SHA1.hexdigest( rand( 9999999 ).to_s )
    end

    def redirect?( res )
        if loc = res.headers_hash['Location']
            return loc
        end
        return res
    end

    def self.info
      { :name => 'HTTP' }
    end

end
end
