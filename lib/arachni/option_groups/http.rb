=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Holds {Arachni::HTTP} related options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class HTTP < Arachni::OptionGroup

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Error

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidProxyType < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidAuthenticationType < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidSSLCertificateType < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidSSLKeyType < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidSSLVersion < Error
        end
    end

    # @return   [Array<String>]
    #   Supported proxy types.
    PROXY_TYPES = %w(http http_1_0 socks4 socks4a socks5 socks5h)

    # @return   [Array<String>]
    #   Supported HTTP authentication types.
    AUTHENTICATION_TYPES = %w(auto basic digest digest_ie negotiate ntlm)

    # @return   [Array<String>]
    #   Supported SSL certificate types.
    SSL_CERTIFICATE_TYPES = %w(pem der)

    # @return   [Array<String>]
    #   Supported SSL private key types.
    SSL_KEY_TYPES = SSL_CERTIFICATE_TYPES

    # @return   [Array<String>]
    #   Supported SSL versions.
    SSL_VERSIONS = %w(TLSv1 TLSv1_0 TLSv1_1 TLSv1_2 SSLv2 SSLv3)

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

    # @note Default is `auto`.
    #
    # @return   [String]
    #   Authentication type
    #
    # @see AUTHENTICATION_TYPES
    attr_accessor :authentication_type

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
    #   HTTP proxy type.
    #
    # @see PROXY_TYPES
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
    #   Cookies in the form of a `Set-Cookie` response header:
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

    # @note Default is 'false'.
    #
    # @return    [Bool]
    #   SSL peer verification.
    attr_accessor :ssl_verify_peer

    # @note Default is 'false'.
    #
    # @return    [Bool]
    #   SSL host verification.
    attr_accessor :ssl_verify_host

    # @return    [String]
    #   Path to an SSL certificate.
    attr_accessor :ssl_certificate_filepath

    # @return    [String]
    #   Type of the certificate at {#ssl_certificate_filepath}.
    #
    # @see SSL_CERTIFICATE_TYPES
    attr_accessor :ssl_certificate_type

    # @return    [String]
    #   Path to an SSL private key.
    attr_accessor :ssl_key_filepath

    # @return    [String]
    #   Type of the key at {#ssl_key_filepath}.
    #
    # @see SSL_KEY_TYPES
    attr_accessor :ssl_key_type

    # @return    [String]
    #   Password for the key at {#ssl_key_filepath}.
    attr_accessor :ssl_key_password

    # @return    [String]
    #   File holding one or more certificates with which to
    #   {#ssl_verify_peer verify the peer}.
    attr_accessor :ssl_ca_filepath

    # @return    [String]
    #   Directory holding multiple certificate files with which to
    #   {#ssl_verify_peer verify the peer}.
    attr_accessor :ssl_ca_directory

    # @return    [String]
    #   SSL version to use.
    #
    # @see SSL_VERSIONS
    attr_accessor :ssl_version

    set_defaults(
        user_agent:             "Arachni/v#{Arachni::VERSION}",
        request_timeout:        10_000,
        request_redirect_limit: 5,
        request_concurrency:    20,
        request_queue_size:     100,
        request_headers:        {},
        response_max_size:      500_000,
        cookies:                {},
        authentication_type:    'auto'
    )

    # @param    [String]    type
    #   One of {AUTHENTICATION_TYPES}.
    #
    # @raise    Error::InvalidAuthenticationType
    def authentication_type=( type )
        return @authentication_type = defaults[:authentication_type].dup if !type

        if !AUTHENTICATION_TYPES.include?( type.to_s )
            fail Error::InvalidAuthenticationType,
                 "Invalid authentication type: #{type} (supported: #{AUTHENTICATION_TYPES.join(', ')})"
        end

        @authentication_type = type
    end

    # @param    [String]    type
    #   One of {PROXY_TYPES}.
    #
    # @raise    Error::InvalidProxyType
    def proxy_type=( type )
        if !PROXY_TYPES.include?( type.to_s )
            fail Error::InvalidProxyType,
                 "Invalid proxy type: #{type} (supported: #{PROXY_TYPES.join(', ')})"
        end

        @proxy_type = type
    end

    # @param    [String]    type
    #   One of {SSL_CERTIFICATE_TYPES}.
    #
    # @raise    Error::InvalidSSLCertificateType
    def ssl_certificate_type=( type )
        if !SSL_CERTIFICATE_TYPES.include?( type.to_s )
            fail Error::InvalidSSLCertificateType,
                 "Invalid SSL certificate type: #{type} (supported: #{SSL_CERTIFICATE_TYPES.join(', ')})"
        end

        @ssl_certificate_type = type
    end

    # @param    [String]    type
    #   One of {SSL_KEY_TYPES}.
    #
    # @raise    Error::InvalidSSLKeyType
    def ssl_key_type=( type )
        if !SSL_KEY_TYPES.include?( type.to_s )
            fail Error::InvalidSSLKeyType,
                 "Invalid SSL key type: #{type} (supported: #{SSL_KEY_TYPES.join(', ')})"
        end

        @ssl_key_type = type
    end

    # @param    [String]    version
    #   One of {SSL_VERSIONS}.
    #
    # @raise    Error::InvalidSSLVersion
    def ssl_version=( version )
        if !SSL_VERSIONS.include?( version.to_s )
            fail Error::InvalidSSLVersion,
                 "Invalid SSL version: #{version} (supported: #{SSL_VERSIONS.join(', ')})"
        end

        @ssl_version = version
    end

    def to_rpc_data
        d = super
        d.delete 'cookie_jar_filepath'
        d
    end

end
end
