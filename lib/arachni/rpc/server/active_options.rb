=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module RPC
class Server

# It, for the most part, forwards calls to {Arachni::Options} and intercepts
# a few that need to be updated at other places throughout the framework.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ActiveOptions

    def initialize( framework )
        @options = framework.options

        %w( url http_request_concurrency http_request_timeout http_user_agent
            http_request_redirect_limit http_proxy_username http_proxy_password
            http_proxy_type http_proxy_host http_proxy_port authorized_by
            http_cookies http_cookie_string http_authentication_username
            http_authentication_password ).each do |m|
            m = "#{m}=".to_sym
            self.class.class_eval do
                define_method m do |v|
                    @options.send( m, v )
                    HTTP::Client.reset false
                    v
                end
            end
        end

        (@options.public_methods( false ) - public_methods( false ) ).each do |m|
            self.class.class_eval do
                define_method m do |*args|
                    @options.send( m, *args )
                end
            end
        end

    end

    # @see Arachni::Options#set
    def set( options )
        @options.set( options )
        HTTP::Client.reset false
        true
    end

    def http_proxy=( proxy_url )
        @options.http.proxy_host, @options.http.proxy_port = proxy_url.to_s.split( ':' )
        @options.http.proxy_port = @options.http.proxy_port.to_i

        HTTP::Client.reset false
        @options.http.proxy = proxy_url
    end

    # @private
    def to_h
        @options.to_rpc_data
    end

end

end
end
end
