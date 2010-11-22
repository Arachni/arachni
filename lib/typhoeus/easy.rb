module Typhoeus
  class Easy
    attr_reader :response_body, :response_header, :method, :headers, :url, :params
    attr_accessor :start_time

    # These integer codes are available in curl/curl.h
    CURLINFO_STRING = 1048576
    OPTION_VALUES = {
      :CURLOPT_URL            => 10002,
      :CURLOPT_HTTPGET        => 80,
      :CURLOPT_HTTPPOST       => 10024,
      :CURLOPT_UPLOAD         => 46,
      :CURLOPT_CUSTOMREQUEST  => 10036,
      :CURLOPT_POSTFIELDS     => 10015,
      :CURLOPT_COPYPOSTFIELDS     => 10165,
      :CURLOPT_POSTFIELDSIZE  => 60,
      :CURLOPT_USERAGENT      => 10018,
      :CURLOPT_TIMEOUT_MS     => 155,
      # Time-out connect operations after this amount of milliseconds.
      # [Only works on unix-style/SIGALRM operating systems. IOW, does
      # not work on Windows.
      :CURLOPT_CONNECTTIMEOUT_MS  => 156,
      :CURLOPT_NOSIGNAL       => 99,
      :CURLOPT_HTTPHEADER     => 10023,
      :CURLOPT_FOLLOWLOCATION => 52,
      :CURLOPT_MAXREDIRS      => 68,
      :CURLOPT_HTTPAUTH       => 107,
      :CURLOPT_USERPWD        => 10000 + 5,
      :CURLOPT_VERBOSE        => 41,
      :CURLOPT_PROXY          => 10004,
      :CURLOPT_PROXYUSERPWD   => 10000 + 6,
      :CURLOPT_PROXYTYPE      => 101,
      :CURLOPT_PROXYAUTH      => 111,
      :CURLOPT_VERIFYPEER     => 64,
      :CURLOPT_NOBODY         => 44,
      :CURLOPT_ENCODING       => 10000 + 102,
      :CURLOPT_SSLCERT        => 10025,
      :CURLOPT_SSLCERTTYPE    => 10086,
      :CURLOPT_SSLKEY         => 10087,
      :CURLOPT_SSLKEYTYPE     => 10088,
      :CURLOPT_KEYPASSWD      => 10026,
      :CURLOPT_CAINFO         => 10065,
      :CURLOPT_CAPATH         => 10097
    }
    PROXY_TYPES = {
      :CURLPROXY_HTTP         => 0,
      :CURLPROXY_HTTP_1_0     => 1,
      :CURLPROXY_SOCKS4       => 4,
      :CURLPROXY_SOCKS5       => 5,
      :CURLPROXY_SOCKS4A      => 6,
    }


    def proxy=(proxy)
      set_option(OPTION_VALUES[:CURLOPT_PROXY], proxy[:server])
      set_option(OPTION_VALUES[:CURLOPT_PROXYTYPE], proxy[:type]) if proxy[:type]
    end

    def proxy_auth=(authinfo)
      set_option(OPTION_VALUES[:CURLOPT_PROXYUSERPWD], "#{authinfo[:username]}:#{authinfo[:password]}")
      set_option(OPTION_VALUES[:CURLOPT_PROXYAUTH], authinfo[:method]) if authinfo[:method]
    end

  end
end
