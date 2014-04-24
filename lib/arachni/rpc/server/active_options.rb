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
        @opts = framework.options

        %w( url http_request_concurrency http_request_timeout http_user_agent
            http_request_redirect_limit http_proxy_username http_proxy_password
            http_proxy_type http_proxy_host http_proxy_port authorized_by http_cookies
            http_cookie_string http_authentication_username http_authentication_password ).each do |m|
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
        @opts.set( options )
        HTTP::Client.reset false
        true
    end

    def http_proxy=( proxy_url )
        @opts.http.proxy_host, @opts.http.proxy_port = proxy_url.to_s.split( ':' )
        @opts.http.proxy_port = @opts.http.proxy_port.to_i

        HTTP::Client.reset false
        @opts.http.proxy = proxy_url
    end

    # @private
    def to_h
        h = @opts.to_h
        %w(exclude_path_patterns exclude_page_patterns include_path_patterns).each do |k|
            h[:scope][k.to_sym] = h[:scope][k.to_sym].map(&:source)
        end

        h[:scope][:redundant_path_patterns] = h[:scope][:redundant_path_patterns].inject({}) do |o, (k, v)|
            o[k.source] = v
            o
        end

        h
    end

end

end
end
end
