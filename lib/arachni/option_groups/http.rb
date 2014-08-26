=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni::OptionGroups

# Holds {Arachni::HTTP} related options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class HTTP < Arachni::OptionGroup

    # @return   [Array<String>]   Supported proxy types.
    PROXY_TYPES = %w(http http_1_0 socks4 socks5 socks4a)

    # @note Default is '5'.
    #
    # @return    [Integer]
    #   Amount of redirects to follow when performing HTTP
    #   {HTTP::Request requests}.
    #
    # @see HTTP::Request
    attr_accessor :request_redirect_limit

    # @note Default is `20`.
    #
    # @return    [Integer]
    #   Maximum HTTP {HTTP::Request request} concurrency. Be careful not to set
    #   this too high or you may kill the server.
    #
    # @see HTTP::Request
    # @see HTTP::Client#max_concurrency=
    # @see HTTP::Client#max_concurrency
    attr_accessor :request_concurrency

    # @note Default is `500`.
    #
    # @return    [Integer]
    #   Maximum amount of {HTTP::Request requests} to keep in the
    #   {HTTP::Client client} queue.
    #
    #   More means better scheduling and better performance, less means
    #   less RAM consumption.
    #
    # @see HTTP::Request
    # @see HTTP::Client
    attr_accessor :request_queue_size

    # @note Default is '50_000'.
    #
    # @return   [Integer]
    #   HTTP {HTTP::Request request} timeout in milliseconds.
    #
    # @see HTTP::Request
    # @see HTTP::Client
    attr_accessor :request_timeout

    # @return   [String]
    #   Username to use for HTTP authentication.
    #
    # @see HTTP::Client
    attr_accessor :authentication_username

    # @return   [String]
    #   Password to use for HTTP authentication.
    #
    # @see HTTP::Client
    attr_accessor :authentication_password

    # @return   [Integer]
    #   Maximum HTTP {Arachni::HTTP::Response response} body size. If a
    #   {Arachni::HTTP::Response#body} is larger than specified it will not be retrieved.
    #
    # @see HTTP::Response
    attr_accessor :response_max_size

    # @return    [String]
    #   Hostname or IP address of the HTTP proxy server to use.
    #
    # @see HTTP::Client
    attr_accessor :proxy_host

    # @return    [Integer]
    #   Port of the HTTP proxy server.
    #
    # @see HTTP::Client
    attr_accessor :proxy_port

    # @return    [String]
    #   Proxy username to use.
    #
    # @see HTTP::Client
    attr_accessor :proxy_username

    # @return    [String]
    #   Proxy password to use.
    #
    # @see HTTP::Client
    attr_accessor :proxy_password

    # @note Default is `auto`.
    #
    # @return    [String]
    #   HTTP proxy type, available options are:
    #
    #   * `http`
    #   * `socks`
    #
    # @see HTTP::Client
    attr_accessor :proxy_type

    # @return    [String]
    #   Proxy URL (`host:port`).
    #
    # @see HTTP::Client
    attr_accessor :proxy

    # @return    [Hash]
    #   Cookies as `name=>value` pairs.
    #
    # @see HTTP::Client
    # @see HTTP::CookieJar
    attr_accessor :cookies

    # @return    [String]
    #   Location of the Netscape-style cookie-jar file.
    #
    # @see HTTP::Client
    # @see HTTP::CookieJar
    attr_accessor :cookie_jar_filepath

    # @return    [String]
    #   Cookies in the form of a:
    #
    #   * Request `Cookie` header: `name=value; name2=value2`
    #   * Response `Set-Cookie` header:
    #       `name2=value2; Expires=Wed, 09 Jun 2021 10:18:14 GMT`
    attr_accessor :cookie_string

    # @note Default is "Arachni/v#{Arachni::VERSION}".
    #
    # @return    [String]
    #   HTTP User-Agent to use.
    #
    # @see HTTP::Client
    attr_accessor :user_agent

    # @return   [Hash<String, String>]
    #   Extra HTTP headers to be included in every HTTP Request
    #
    # @see HTTP::Client#headers
    attr_accessor :request_headers

    set_defaults(
        user_agent:             "Arachni/v#{Arachni::VERSION}",
        request_timeout:        50_000,
        request_redirect_limit: 5,
        request_concurrency:    20,
        request_queue_size:     500,
        request_headers:        {},
        cookies:                {}
    )

    def to_rpc_data
        d = super
        d.delete 'cookie_jar_filepath'
        d
    end

end
end
