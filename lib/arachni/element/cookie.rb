=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'webrick'
require 'uri'

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

COOKIE = 'cookie'

#
# Represents a Cookie object and provides helper class methods for parsing, encoding, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Cookie < Arachni::Element::Base

    #
    # Default cookie values
    #
    DEFAULT = {
           "name" => nil,
          "value" => nil,
        "version" => 0,
           "port" => nil,
        "discard" => nil,
    "comment_url" => nil,
        "expires" => nil,
        "max_age" => nil,
        "comment" => nil,
         "secure" => nil,
           "path" => nil,
         "domain" => nil,
       "httponly" => false
    }

    def initialize( url, raw = {} )
        super( url, raw )

        self.action = @url
        self.method = 'get'

        @raw ||= {}
        if @raw['name'] && @raw['value']
            self.auditable = { @raw['name'] => @raw['value'] }
        else
            self.auditable = raw.dup
        end

        @raw = @raw.merge( DEFAULT.merge( @raw ) )
        if @raw['value'] && !@raw['value'].empty?
            @raw['value'] = decode( @raw['value'].to_s )
        end

        parsed_uri = uri_parse( @url )
        if !@raw['path']
            path = parsed_uri.path
            path = !path.empty? ? path : '/'
            @raw['path'] = path
        end

        @raw['domain'] ||= parsed_uri.host

        @raw['max_age'] = @raw['max_age'] if @raw['max_age']

        @orig   = self.auditable.dup
        @orig.freeze
    end

    #
    # Overrides {Capabilities::Auditable#audit} to enforce cookie exclusion
    # settings from {Arachni::Options#exclude_cookies}.
    #
    # @see Capabilities::Auditable#audit
    #
    def audit( *args )
        if Arachni::Options.exclude_cookies.include?( name )
            auditor.print_info "Skipping audit of '#{name}' cookie."
            return
        end
        super( *args )
    end

    #
    # Indicates whether the cookie must be only sent over an encrypted channel.
    #
    # @example
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; secure' ).first.secure?
    #    #=> true
    #
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.secure?
    #    #=> false
    #
    # @return   [Bool]
    #
    def secure?
        @raw['secure'] == true
    end

    #
    # Indicates whether the cookie is safe from modification from client-side code.
    #
    # @example
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; httpOnly' ).first.http_only?
    #    #=> true
    #
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.http_only?
    #    #=> false
    #
    # @return   [Bool]
    #
    def http_only?
        @raw['httponly'] == true
    end

    #
    # Indicates whether the cookie is to be discarded at the end of the session.
    #
    # Doesn't play a role during the scan but it can provide useful info to modules and such.
    #
    # @example
    #    # doesn't have an expiration date, i.e. it should be discarded at the end of the session
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.session?
    #    #=> true
    #
    #    # does have an expiration date, i.e. not a session cookie
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; Expires=Thu, 01 Jan 1970 00:00:01 GMT' ).first.session?
    #    #=> false
    #
    # @return   [Bool]
    #
    def session?
        @raw['expires'].nil?
    end

    #
    # @example
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.expires_at
    #    #=> nil
    #
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; Expires=Thu, 01 Jan 1970 00:00:01 GMT' ).first.expires_at
    #    #=> 1970-01-01 02:00:01 +0200
    #
    #
    # @return   [Time, NilClass]
    #   Expiration `Time` of the cookie or `nil` if it doesn't have one
    #   (i.e. is a session cookie).
    #
    def expires_at
        expires
    end

    #
    # Indicates whether or not the cookie has expired.
    #
    # @example Without a time argument.
    #
    #    # session cookie
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.expired?
    #    #=> false
    #
    #    # cookie with the expiration date in the future
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; Expires=Thu, 01 Jan 2020 00:00:01 GMT' ).first.expired?
    #    #=> true
    #
    #    # expired cookie
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; Expires=Thu, 01 Jan 1970 00:00:01 GMT' ).first.expired?
    #    #=> true
    #
    # @example With a time argument.
    #
    #    future_time = Cookie.expires_to_time( 'Thu, 01 Jan 2021 00:00:01 GMT' )
    #
    #    # session cookie
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.expired?( future_time )
    #    #=> false
    #
    #    # cookie with the expiration date in the future
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; Expires=Thu, 01 Jan 2020 00:00:01 GMT' ).first.expired?( future_time )
    #    #=> true
    #
    #    # expired cookie
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff; Expires=Thu, 01 Jan 1970 00:00:01 GMT' ).first.expired?( future_time )
    #    #=> true
    #
    # @param    [Time]    time    To compare against.
    #
    # @return [Boolean]
    #
    def expired?( time = Time.now )
        expires_at != nil && time > expires_at
    end

    #
    # @example
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.simple
    #    #=> {"session"=>"stuffstuffstuff"}
    #
    #
    # @return   [Hash]
    #   Simple representation of the cookie as a hash -- with the cookie name as
    #   `key` and the cookie value as `value`.
    def simple
        self.auditable.dup
    end

    # @return   [String]    Name of the current element, 'cookie' in this case.
    # @see Arachni::Element::COOKIE
    def type
        Arachni::Element::COOKIE
    end

    def dup
        super.tap { |d| d.action = self.action }
    end

    #
    # @example
    #    p c = Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first
    #    #=> ["session=stuffstuffstuff"]
    #
    #    p c.auditable
    #    #=> {"session"=>"stuffstuffstuff"}
    #
    #    p c.auditable = { 'new-name' => 'new-value' }
    #    #=> {"new-name"=>"new-value"}
    #
    #    p c
    #    #=> new-name=new-value
    #
    #
    # @param    [Hash]  inputs   Sets auditable inputs.
    #
    def auditable=( inputs )
        k = inputs.keys.first.to_s
        v = inputs.values.first.to_s

        raw = @raw.dup
        raw['name']  = k
        raw['value'] = v

        @raw = raw.freeze

        if k.to_s.empty?
            super( {} )
        else
            super( { k => v } )
        end
    end

    #
    # Overrides {Capabilities::Mutable#mutations} to handle cookie-specific
    # limitations and the {Arachni::Options#audit_cookies_extensively} option.
    #
    #     c = Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first
    #
    # @example Default
    #     p c.mutations 'seed'
    #     #=> [session=seed, session=stuffstuffstuffseed, session=seed%00, session=stuffstuffstuffseed%00]
    #
    # @example With parameter flip
    #    p c.mutations 'seed', param_flip: true
    #    #=> [session=seed, session=stuffstuffstuffseed, session=seed%00, session=stuffstuffstuffseed%00, seed=eb987f5d6a6948193f3677ee70eaedf0e1454f1eb715322ec627f0a32848f8bd]
    #
    # @example Extensive audit
    #
    #    Arachni::Options.audit_cookies_extensively = true
    #
    #    # this option presupposes that an auditor (with page) is available
    #    Auditor = Class.new do
    #        include Arachni::Module::Auditor
    #
    #        def page
    #            Page.new( links: [Link.new( 'http://owner-url.com', input1: 'value1' )] )
    #        end
    #
    #        def self.info
    #            { name: 'My custom auditor' }
    #        end
    #    end
    #
    #    c.auditor = Auditor.new
    #
    #    p mutations = c.mutations( 'seed' )
    #    #=> [session=seed, session=stuffstuffstuffseed, session=seed%00, session=stuffstuffstuffseed%00, http://owner-url.com/?input1=value1, http://owner-url.com/?input1=value1, http://owner-url.com/?input1=value1, http://owner-url.com/?input1=value1]
    #
    #    # if we take a closer look at the Link mutations we see that this link will be submitted with various cookie mutations
    #    ap mutations.select { |m| m.is_a? Link }
    #    #=> [
    #    #     [0] #<Arachni::Element::Link:0x02de90e8
    #    #         @audit_id_url = "http://owner-url.com/",
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :altered = "mutation for the 'session' cookie",
    #    #         attr_accessor :auditable = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_accessor :auditor = #<Auditor:0x000000029e7648>,
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -4537574543719230301,
    #    #         attr_reader :opts = {
    #    #             :cookies => {
    #    #                 "session" => "seed"
    #    #             }
    #    #         },
    #    #         attr_reader :orig = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_reader :raw = {
    #    #             :input1 => "value1"
    #    #         }
    #    #     >,
    #    #     [1] #<Arachni::Element::Link:0x02df3f98
    #    #         @audit_id_url = "http://owner-url.com/",
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :altered = "mutation for the 'session' cookie",
    #    #         attr_accessor :auditable = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_accessor :auditor = #<Auditor:0x000000029e7648>,
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -4537574543719230301,
    #    #         attr_reader :opts = {
    #    #             :cookies => {
    #    #                 "session" => "stuffstuffstuffseed"
    #    #             }
    #    #         },
    #    #         attr_reader :orig = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_reader :raw = {
    #    #             :input1 => "value1"
    #    #         }
    #    #     >,
    #    #     [2] #<Arachni::Element::Link:0x02adcf80
    #    #         @audit_id_url = "http://owner-url.com/",
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :altered = "mutation for the 'session' cookie",
    #    #         attr_accessor :auditable = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_accessor :auditor = #<Auditor:0x000000029e7648>,
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -4537574543719230301,
    #    #         attr_reader :opts = {
    #    #             :cookies => {
    #    #                 "session" => "seed\x00"
    #    #             }
    #    #         },
    #    #         attr_reader :orig = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_reader :raw = {
    #    #             :input1 => "value1"
    #    #         }
    #    #     >,
    #    #     [3] #<Arachni::Element::Link:0x02b0c0a0
    #    #         @audit_id_url = "http://owner-url.com/",
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :altered = "mutation for the 'session' cookie",
    #    #         attr_accessor :auditable = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_accessor :auditor = #<Auditor:0x000000029e7648>,
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -4537574543719230301,
    #    #         attr_reader :opts = {
    #    #             :cookies => {
    #    #                 "session" => "stuffstuffstuffseed\x00"
    #    #             }
    #    #         },
    #    #         attr_reader :orig = {
    #    #             "input1" => "value1"
    #    #         },
    #    #         attr_reader :raw = {
    #    #             :input1 => "value1"
    #    #         }
    #    #     >
    #    # ]
    #
    #
    # @see Capabilities::Mutable#mutations
    #
    def mutations( injection_str, opts = {} )
        flip = opts.delete( :param_flip )
        muts = super( injection_str, opts )

        if flip
            elem = self.dup

            # when under HPG mode element auditing is strictly regulated
            # and when we flip params we essentially create a new element
            # which won't be on the whitelist
            elem.override_instance_scope

            elem.altered = 'Parameter flip'
            elem.auditable = { injection_str => seed }
            muts << elem
        end

        if !orphan? && Arachni::Options.audit_cookies_extensively?
            # submit all links and forms of the page along with our cookie mutations
            muts << muts.map do |m|
                (auditor.page.links | auditor.page.forms).map do |e|
                    next if e.auditable.empty?
                    c = e.dup
                    c.altered = "mutation for the '#{m.altered}' cookie"
                    c.auditor = auditor
                    c.opts[:cookies] = m.auditable.dup
                    c.auditable = Arachni::Module::KeyFiller.fill( c.auditable.dup )
                    c
                end
            end.flatten.compact
            muts.flatten!
        end

        muts
    end

    #
    # Uses the method name as a key to cookie attributes in {DEFAULT}.
    #
    # @example
    #    c = Cookie.from_set_cookie( 'http://owner-url.com/stuff', 'session=stuffstuffstuff' ).first
    #
    #    p c.name
    #    #=> "session"
    #
    #    p c.value
    #    #=> "stuffstuffstuff"
    #
    #    p c.path
    #    #=> "/stuff"
    #
    #
    def method_missing( sym, *args, &block )
        return @raw[sym.to_s] if respond_to?( sym )
        super( sym, *args, &block )
    end

    #
    # Used by {#method_missing} to determine if it should process the call.
    #
    # @return   [Bool]
    #
    def respond_to?( sym )
        (@raw && @raw.include?( sym.to_s )) || super( sym )
    end

    #
    # @example
    #    p Cookie.from_set_cookie( 'http://owner-url.com/', 'session=stuffstuffstuff' ).first.to_s
    #    #=> "session=stuffstuffstuff"
    #
    #    p Cookie.new( 'http://owner-url.com/', '% ; freaky name' => 'freaky value;%' ).to_s
    #    #=> "%25+%3B+freaky+name=freaky+value%3B%25"
    #
    #
    # @return   [String]    To be used in a `Cookie` HTTP request header.
    #
    def to_s
        "#{encode( name )}=#{encode( value )}"
    end

    #
    # Parses a Netscape Cookie-jar into an Array of {Cookie}.
    #
    # @example Parsing a Netscape HTTP cookiejar file
    #
    #   # Given a cookie-jar file with the following contents:
    #   #
    #   #   # comment, should be ignored
    #   #   .domain.com	TRUE	/path/to/somewhere	TRUE	Tue, 02 Oct 2012 19:25:57 GMT	first_name	first_value
    #   #
    #   #   # ignored again
    #   #   another-domain.com	FALSE	/	FALSE	second_name	second_value
    #   #
    #   #   # with expiry date as seconds since epoch
    #   #   .blah-domain	TRUE	/	FALSE	1596981560	NAME	OP5jTLV6VhYHADJAbJ1ZR@L8~081210
    #
    #   p Cookie.from_file 'http://owner-url.com', 'cookies.jar'
    #   #=> [first_name=first_value, second_name=second_value, NAME=OP5jTLV6VhYHADJAbJ1ZR@L8~081210]
    #
    #   # And here's the fancier dump:
    #   # [
    #   #     [0] #<Arachni::Element::Cookie:0x011636d0
    #   #         attr_accessor :action = "http://owner-url.com/",
    #   #         attr_accessor :auditable = {
    #   #             "first_name" => "first_value"
    #   #         },
    #   #         attr_accessor :method = "get",
    #   #         attr_accessor :url = "http://owner-url.com/",
    #   #         attr_reader :hash = -473180912834263695,
    #   #         attr_reader :opts = {},
    #   #         attr_reader :orig = {
    #   #             "first_name" => "first_value"
    #   #         },
    #   #         attr_reader :raw = {
    #   #                  "domain" => ".domain.com",
    #   #                    "path" => "/path/to/somewhere",
    #   #                  "secure" => true,
    #   #                 "expires" => 2012-10-02 22:25:57 +0300,
    #   #                    "name" => "first_name",
    #   #                   "value" => "first_value",
    #   #                 "version" => 0,
    #   #                    "port" => nil,
    #   #                 "discard" => nil,
    #   #             "comment_url" => nil,
    #   #                 "max_age" => nil,
    #   #                 "comment" => nil,
    #   #                "httponly" => false
    #   #         }
    #   #     >,
    #   #     [1] #<Arachni::Element::Cookie:0x011527b8
    #   #         attr_accessor :action = "http://owner-url.com/",
    #   #         attr_accessor :auditable = {
    #   #             "second_name" => "second_value"
    #   #         },
    #   #         attr_accessor :method = "get",
    #   #         attr_accessor :url = "http://owner-url.com/",
    #   #         attr_reader :hash = -2673771862017142861,
    #   #         attr_reader :opts = {},
    #   #         attr_reader :orig = {
    #   #             "second_name" => "second_value"
    #   #         },
    #   #         attr_reader :raw = {
    #   #                  "domain" => "another-domain.com",
    #   #                    "path" => "/",
    #   #                  "secure" => false,
    #   #                 "expires" => nil,
    #   #                    "name" => "second_name",
    #   #                   "value" => "second_value",
    #   #                 "version" => 0,
    #   #                    "port" => nil,
    #   #                 "discard" => nil,
    #   #             "comment_url" => nil,
    #   #                 "max_age" => nil,
    #   #                 "comment" => nil,
    #   #                "httponly" => false
    #   #         }
    #   #     >,
    #   #     [2] #<Arachni::Element::Cookie:0x011189f0
    #   #         attr_accessor :action = "http://owner-url.com/",
    #   #         attr_accessor :auditable = {
    #   #             "NAME" => "OP5jTLV6VhYHADJAbJ1ZR@L8~081210"
    #   #         },
    #   #         attr_accessor :method = "get",
    #   #         attr_accessor :url = "http://owner-url.com/",
    #   #         attr_reader :hash = 4086929775905476282,
    #   #         attr_reader :opts = {},
    #   #         attr_reader :orig = {
    #   #             "NAME" => "OP5jTLV6VhYHADJAbJ1ZR@L8~081210"
    #   #         },
    #   #         attr_reader :raw = {
    #   #                  "domain" => ".blah-domain",
    #   #                    "path" => "/",
    #   #                  "secure" => false,
    #   #                 "expires" => 2020-08-09 16:59:20 +0300,
    #   #                    "name" => "NAME",
    #   #                   "value" => "OP5jTLV6VhYHADJAbJ1ZR@L8~081210",
    #   #                 "version" => 0,
    #   #                    "port" => nil,
    #   #                 "discard" => nil,
    #   #             "comment_url" => nil,
    #   #                 "max_age" => nil,
    #   #                 "comment" => nil,
    #   #                "httponly" => false
    #   #         }
    #   #     >
    #   # ]
    #
    #
    # @param   [String]    url          request URL
    # @param   [String]    filepath     Netscape HTTP cookiejar file
    #
    # @return   [Array<Cookie>]
    #
    # @see http://curl.haxx.se/rfc/cookie_spec.html
    #
    def self.from_file( url, filepath )
        File.open( filepath, 'r' ).map do |line|
            # skip empty lines
            next if (line = line.strip).empty? || line[0] == '#'

            c = {}
            c['domain'], foo, c['path'], c['secure'], c['expires'], c['name'],
                c['value'] = *line.split( "\t" )

            # expiry date is optional so if we don't have one push everything back
            begin
                c['expires'] = expires_to_time( c['expires'] )
            rescue
                c['value'] = c['name'].dup
                c['name'] = c['expires'].dup
                c['expires'] = nil
            end
            c['secure'] = (c['secure'] == 'TRUE') ? true : false
            new( url, c )
        end.flatten.compact
    end

    #
    # Converts a cookie's expiration date to a Ruby `Time` object.
    #
    # @example String time format
    #    p Cookie.expires_to_time "Tue, 02 Oct 2012 19:25:57 GMT"
    #    #=> 2012-10-02 22:25:57 +0300
    #
    # @example Seconds since Epoch
    #    p Cookie.expires_to_time "1596981560"
    #    #=> 2020-08-09 16:59:20 +0300
    #
    #    p Cookie.expires_to_time 1596981560
    #    #=> 2020-08-09 16:59:20 +0300
    #
    # @param    [String]    expires
    #
    # @return   [Time]
    #
    def self.expires_to_time( expires )
        return nil if expires == '0'
        (expires_to_i = expires.to_i) > 0 ? Time.at( expires_to_i ) : Time.parse( expires )
    end

    #
    # Extracts cookies from an HTTP {Typhoeus::Response response}.
    #
    # @example
    #    body = <<-HTML
    #        <html>
    #            <head>
    #                <meta http-equiv="Set-Cookie" content="cookie=val; httponly">
    #                <meta http-equiv="Set-Cookie" content="cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly; secure">
    #            </head>
    #        </html>
    #    HTML
    #
    #    response = Typhoeus::Response.new(
    #        body:          body,
    #        effective_url: 'http://stuff.com',
    #        headers_hash:  {
    #           'Set-Cookie' => "coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly"
    #       }
    #    )
    #
    #    p Cookie.from_response response
    #    # [cookie=val, cookie2=val2, coo@ki+e2=blah+val2@]
    #
    #    # Fancy dump:
    #    # [
    #    #     [0] #<Arachni::Element::Cookie:0x028e30f8
    #    #         attr_accessor :action = "http://stuff.com/",
    #    #         attr_accessor :auditable = {
    #    #             "cookie" => "val"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://stuff.com/",
    #    #         attr_reader :hash = 2101892390575163651,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "cookie" => "val"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "cookie",
    #    #                   "value" => "val",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => nil,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => nil,
    #    #                    "path" => "/",
    #    #                  "domain" => "stuff.com",
    #    #                "httponly" => true
    #    #         }
    #    #     >,
    #    #     [1] #<Arachni::Element::Cookie:0x028ec0e0
    #    #         attr_accessor :action = "http://stuff.com/",
    #    #         attr_accessor :auditable = {
    #    #             "cookie2" => "val2"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://stuff.com/",
    #    #         attr_reader :hash = 1525536412599744532,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "cookie2" => "val2"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "cookie2",
    #    #                   "value" => "val2",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => 1970-01-01 02:00:01 +0200,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => true,
    #    #                    "path" => "/",
    #    #                  "domain" => ".foo.com",
    #    #                "httponly" => true
    #    #         }
    #    #     >,
    #    #     [2] #<Arachni::Element::Cookie:0x028ef3f8
    #    #         attr_accessor :action = "http://stuff.com/",
    #    #         attr_accessor :auditable = {
    #    #             "coo@ki e2" => "blah val2@"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://stuff.com/",
    #    #         attr_reader :hash = 3179884445716720825,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "coo@ki e2" => "blah val2@"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "coo@ki e2",
    #    #                   "value" => "blah val2@",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => 1970-01-01 02:00:01 +0200,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => nil,
    #    #                    "path" => "/",
    #    #                  "domain" => ".foo.com",
    #    #                "httponly" => true
    #    #         }
    #    #     >
    #    # ]
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Cookie>]
    #
    # @see .from_document
    # @see .from_headers
    #
    def self.from_response( response )
        ( from_document( response.effective_url, response.body ) |
         from_headers( response.effective_url, response.headers_hash ) )
    end

    #
    # Extracts cookies from a document based on `Set-Cookie` `http-equiv` meta tags.
    #
    # @example
    #
    #    body = <<-HTML
    #        <html>
    #            <head>
    #                <meta http-equiv="Set-Cookie" content="cookie=val; httponly">
    #                <meta http-equiv="Set-Cookie" content="cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly; secure">
    #            </head>
    #        </html>
    #    HTML
    #
    #    p Cookie.from_document 'http://owner-url.com', body
    #    #=> [cookie=val, cookie2=val2]
    #
    #    p Cookie.from_document 'http://owner-url.com', Nokogiri::HTML( body )
    #    #=> [cookie=val, cookie2=val2]
    #
    #    # Fancy dump:
    #    # [
    #    #     [0] #<Arachni::Element::Cookie:0x02a23030
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :auditable = {
    #    #             "cookie" => "val"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = 1135494168462266792,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "cookie" => "val"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "cookie",
    #    #                   "value" => "val",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => nil,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => nil,
    #    #                    "path" => "/",
    #    #                  "domain" => "owner-url.com",
    #    #                "httponly" => true
    #    #         }
    #    #     >,
    #    #     [1] #<Arachni::Element::Cookie:0x026745b0
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :auditable = {
    #    #             "cookie2" => "val2"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -765632517082248204,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "cookie2" => "val2"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "cookie2",
    #    #                   "value" => "val2",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => 1970-01-01 02:00:01 +0200,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => true,
    #    #                    "path" => "/",
    #    #                  "domain" => ".foo.com",
    #    #                "httponly" => true
    #    #         }
    #    #     >
    #    # ]
    #
    # @param    [String]    url     Owner URL.
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Cookie>]
    #
    # @see .parse_set_cookie
    #
    def self.from_document( url, document )
        # optimizations in case there are no cookies in the doc,
        # avoid parsing unless absolutely necessary!
        if !document.is_a?( Nokogiri::HTML::Document )
            # get get the head in order to check if it has an http-equiv for set-cookie
            head = document.to_s.match( /<head(.*)<\/head>/imx )

            # if it does feed the head to the parser in order to extract the cookies
            return [] if !head || !head.to_s.downcase.substring?( 'set-cookie' )

            document = Nokogiri::HTML( head.to_s )
        end

        Arachni::Utilities.exception_jail {
            document.search( "//meta[@http-equiv]" ).map do |elem|
                next if elem['http-equiv'].downcase != 'set-cookie'
                parse_set_cookie( url, elem['content'] )
            end.flatten.compact
        } rescue []
    end

    #
    # Extracts cookies from the `Set-Cookie` HTTP response header field.
    #
    # @example
    #    p Cookie.from_headers 'http://owner-url.com', { 'Set-Cookie' => "coo%40ki+e2=blah+val2%40" }
    #    #=> [coo@ki+e2=blah+val2@]
    #
    #    # Fancy dump:
    #    # [
    #    #     [0] #<Arachni::Element::Cookie:0x01e17250
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :auditable = {
    #    #             "coo@ki e2" => "blah val2@"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -1249755840178478661,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "coo@ki e2" => "blah val2@"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "coo@ki e2",
    #    #                   "value" => "blah val2@",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => nil,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => nil,
    #    #                    "path" => "/",
    #    #                  "domain" => "owner-url.com",
    #    #                "httponly" => false
    #    #         }
    #    #     >
    #    # ]
    #
    # @param    [String]    url     request URL
    # @param    [Hash]      headers
    #
    # @return   [Array<Cookie>]
    #
    # @see .forms_set_cookie
    #
    def self.from_headers( url, headers )
        set_strings = []
        headers.each { |k, v| set_strings = [v].flatten if k.downcase == 'set-cookie' }

        return set_strings if set_strings.empty?
        exception_jail {
            set_strings.map { |c| parse_set_cookie( url, c ) }.flatten
        } rescue []
    end

    #
    # Parses the `Set-Cookie` header value into cookie elements.
    #
    # @example
    #    p Cookie.from_set_cookie 'http://owner-url.com', "coo%40ki+e2=blah+val2%40"
    #    #=> [coo@ki+e2=blah+val2@]
    #
    #    # Fancy dump:
    #    # [
    #    #     [0] #<Arachni::Element::Cookie:0x01e17250
    #    #         attr_accessor :action = "http://owner-url.com/",
    #    #         attr_accessor :auditable = {
    #    #             "coo@ki e2" => "blah val2@"
    #    #         },
    #    #         attr_accessor :method = "get",
    #    #         attr_accessor :url = "http://owner-url.com/",
    #    #         attr_reader :hash = -1249755840178478661,
    #    #         attr_reader :opts = {},
    #    #         attr_reader :orig = {
    #    #             "coo@ki e2" => "blah val2@"
    #    #         },
    #    #         attr_reader :raw = {
    #    #                    "name" => "coo@ki e2",
    #    #                   "value" => "blah val2@",
    #    #                 "version" => 0,
    #    #                    "port" => nil,
    #    #                 "discard" => nil,
    #    #             "comment_url" => nil,
    #    #                 "expires" => nil,
    #    #                 "max_age" => nil,
    #    #                 "comment" => nil,
    #    #                  "secure" => nil,
    #    #                    "path" => "/",
    #    #                  "domain" => "owner-url.com",
    #    #                "httponly" => false
    #    #         }
    #    #     >
    #    # ]
    #
    #
    # @param    [String]    url     Request URL.
    # @param    [Hash]      str     `Set-Cookie` string
    #
    # @return   [Array<Cookie>]
    #
    def self.from_set_cookie( url, str )
        WEBrick::Cookie.parse_set_cookies( str ).flatten.uniq.map do |cookie|
            cookie_hash = {}
            cookie.instance_variables.each do |var|
                cookie_hash[var.to_s.gsub( /@/, '' )] = cookie.instance_variable_get( var )
            end
            cookie_hash['expires'] = cookie.expires

            cookie_hash['path'] ||= '/'
            cookie_hash['name']  = decode( cookie.name )
            cookie_hash['value'] = decode( cookie.value )

            new( url.to_s, cookie_hash )
        end.flatten.compact
    end
    def self.parse_set_cookie( *args )
        from_set_cookie( *args )
    end

    #
    # Parses a string formatted for the `Cookie` HTTP request header field
    # into cookie elements.
    #
    # @example
    #    p Cookie.from_string 'http://owner-url.com', "coo%40ki+e2=blah+val2%40;name=value;name2=value2"
    #    #=> [coo@ki+e2=blah+val2@, name=value, name2=value2]
    #
    #     # Fancy dump:
    #     #     [
    #     #         [0] #<Arachni::Element::Cookie:0x01c31558
    #     #             attr_accessor :action = "http://owner-url.com/",
    #     #             attr_accessor :auditable = {
    #     #                 "coo@ki e2" => "blah val2@"
    #     #             },
    #     #             attr_accessor :method = "get",
    #     #             attr_accessor :url = "http://owner-url.com/",
    #     #             attr_reader :hash = 3934200888666098208,
    #     #             attr_reader :opts = {},
    #     #             attr_reader :orig = {
    #     #                 "coo@ki e2" => "blah val2@"
    #     #             },
    #     #             attr_reader :raw = {
    #     #                 "coo@ki e2" => "blah val2@",
    #     #                     "name" => "coo@ki e2",
    #     #                     "value" => "blah val2@",
    #     #                     "version" => 0,
    #     #                     "port" => nil,
    #     #                     "discard" => nil,
    #     #                 "comment_url" => nil,
    #     #                     "expires" => nil,
    #     #                     "max_age" => nil,
    #     #                     "comment" => nil,
    #     #                     "secure" => nil,
    #     #                     "path" => "/",
    #     #                     "domain" => "owner-url.com",
    #     #                 "httponly" => false
    #     #             }
    #     #         >,
    #     #         [1] #<Arachni::Element::Cookie:0x01b17fc8
    #     #             attr_accessor :action = "http://owner-url.com/",
    #     #             attr_accessor :auditable = {
    #     #                 "name" => "value"
    #     #             },
    #     #             attr_accessor :method = "get",
    #     #             attr_accessor :url = "http://owner-url.com/",
    #     #             attr_reader :hash = -2610555034726366868,
    #     #             attr_reader :opts = {},
    #     #             attr_reader :orig = {
    #     #                 "name" => "value"
    #     #             },
    #     #             attr_reader :raw = {
    #     #                     "name" => "name",
    #     #                     "value" => "value",
    #     #                     "version" => 0,
    #     #                     "port" => nil,
    #     #                     "discard" => nil,
    #     #                 "comment_url" => nil,
    #     #                     "expires" => nil,
    #     #                     "max_age" => nil,
    #     #                     "comment" => nil,
    #     #                     "secure" => nil,
    #     #                     "path" => "/",
    #     #                     "domain" => "owner-url.com",
    #     #                 "httponly" => false
    #     #             }
    #     #         >,
    #     #         [2] #<Arachni::Element::Cookie:0x01767b08
    #     #             attr_accessor :action = "http://owner-url.com/",
    #     #             attr_accessor :auditable = {
    #     #                 "name2" => "value2"
    #     #             },
    #     #             attr_accessor :method = "get",
    #     #             attr_accessor :url = "http://owner-url.com/",
    #     #             attr_reader :hash = 3819162339364446155,
    #     #             attr_reader :opts = {},
    #     #             attr_reader :orig = {
    #     #                 "name2" => "value2"
    #     #             },
    #     #             attr_reader :raw = {
    #     #                     "name2" => "value2",
    #     #                     "name" => "name2",
    #     #                     "value" => "value2",
    #     #                     "version" => 0,
    #     #                     "port" => nil,
    #     #                     "discard" => nil,
    #     #                 "comment_url" => nil,
    #     #                     "expires" => nil,
    #     #                     "max_age" => nil,
    #     #                     "comment" => nil,
    #     #                     "secure" => nil,
    #     #                     "path" => "/",
    #     #                     "domain" => "owner-url.com",
    #     #                 "httponly" => false
    #     #             }
    #     #         >
    #     #     ]
    #
    #
    # @param    [String]    url     Request URL.
    # @param    [Hash]      string  `Set-Cookie` string.
    #
    # @return   [Array<Cookie>]
    #
    def self.from_string( url, string )
        string.split( ';' ).map do |cookie_pair|
            k, v = *cookie_pair.split( '=', 2 )
            new( url, decode( k.strip ) => decode( v.strip ) )
        end.flatten.compact
    end

    #
    # Encodes a {String}'s reserved characters in order to prepare it for
    # the `Cookie` header field.
    #
    # @example
    #    p Cookie.encode "+;%=\0 "
    #    #=> "%2B%3B%25%3D%00+"
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    def self.encode( str )
        URI.encode( str, "+;%=\0" ).gsub( ' ', '+' )
    end
    # @see .encode
    def encode( str )
        self.class.encode( str )
    end

    #
    # Decodes a {String} encoded for the `Cookie` header field.
    #
    # @example
    #    p Cookie.decode "%2B%3B%25%3D%00+"
    #    #=> "+;%=\x00 "
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    def self.decode( str )
        URI.decode( str.gsub( '+', ' ' ) )
    end
    # @see .decode
    def decode( str )
        self.class.decode( str )
    end

    private
    def http_request( opts = {}, &block )
        opts[:cookies] = opts[:params].dup
        opts[:params] = {}

        self.method.downcase.to_s != 'get' ?
            http.post( self.action, opts, &block ) : http.get( self.action, opts, &block )
    end

end
end

Arachni::Cookie = Arachni::Element::Cookie
