=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module RPC
class Server

#
# It, for the most part, forwards calls to {::Arachni::Options} and intercepts
# a few that need to be updated at other places throughout the framework.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class ActiveOptions

    def initialize( framework )
        @opts = framework.opts

        %w( url http_req_limit http_timeout user_agent redirect_limit proxy_username
            proxy_password proxy_type proxy_host proxy_port authed_by cookies
            cookie_string http_username http_password ).each do |m|
            m = "#{m}=".to_sym
            self.class.class_eval do
                define_method m do |v|
                    @opts.send( m, v )
                    HTTP::Client.reset false
                    v
                end
            end
        end

        (@opts.public_methods( false ) - public_methods( false ) ).each do |m|
            self.class.class_eval do
                define_method m do |*args|
                    @opts.send( m, *args )
                end
            end
        end

    end

    # @see Arachni::Options#set
    def set( options )
        options.each do |k, v|
            begin
                send( "#{k.to_s}=", v )
            rescue => e
                #ap e
                #ap e.backtrace
            end
        end

        HTTP::Client.reset false
        true
    end

    def proxy=( proxy_url )
        @opts.proxy_host, @opts.proxy_port = proxy_url.to_s.split( /:/ )
        @opts.proxy_port = @opts.proxy_port.to_i

        HTTP::Client.reset false
        @opts.proxy = proxy_url
    end

    def cookie_jar=( cookie_jar )
        HTTP::Client.update_cookies( cookie_jar )
        @cookie_jar = cookie_jar
    end

end

end
end
end
