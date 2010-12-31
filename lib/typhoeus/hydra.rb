=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# Overrides get_easy_object() adding proxy support. <br/>
# This is a temporary solution until the next release of Typhoeus.
#
module Typhoeus
  class Hydra

    def get_easy_object(request)
      @running_requests += 1

      easy = @easy_pool.pop || Easy.new
      easy.verbose          = request.verbose
      if request.username || request.password
        auth = { :username => request.username, :password => request.password }
        auth[:method] = Typhoeus::Easy::AUTH_TYPES["CURLAUTH_#{request.auth_method.to_s.upcase}".to_sym] if request.auth_method
        easy.auth = auth
      end

      if request.proxy
        proxy = { :server => request.proxy }
        proxy[:type] = Typhoeus::Easy::PROXY_TYPES["CURLPROXY_#{request.proxy_type.to_s.upcase}".to_sym] if request.proxy_type
        easy.proxy = proxy if request.proxy
      end

      if request.proxy_username || request.proxy_password
        auth = { :username => request.proxy_username, :password => request.proxy_password }
        auth[:method] = Typhoeus::Easy::AUTH_TYPES["CURLAUTH_#{request.proxy_auth_method.to_s.upcase}".to_sym] if request.proxy_auth_method
        easy.proxy_auth = auth
      end

      easy.url          = request.url
      easy.method       = request.method
      easy.params       = request.params  if request.method == :post && !request.params.nil?
      easy.headers      = request.headers if request.headers
      easy.request_body = request.body    if request.body
      easy.timeout      = request.timeout if request.timeout
      easy.connect_timeout = request.connect_timeout if request.connect_timeout
      easy.follow_location = request.follow_location if request.follow_location
      easy.max_redirects = request.max_redirects if request.max_redirects
      easy.disable_ssl_peer_verification if request.disable_ssl_peer_verification
      easy.ssl_cert         = request.ssl_cert
      easy.ssl_cert_type    = request.ssl_cert_type
      easy.ssl_key          = request.ssl_key
      easy.ssl_key_type     = request.ssl_key_type
      easy.ssl_key_password = request.ssl_key_password
      easy.ssl_cacert       = request.ssl_cacert
      easy.ssl_capath       = request.ssl_capath
      easy.verbose          = request.verbose

      easy.on_success do |easy|
        queue_next
        handle_request(request, response_from_easy(easy, request))
        release_easy_object(easy)
      end
      easy.on_failure do |easy|
        queue_next
        handle_request(request, response_from_easy(easy, request))
        release_easy_object(easy)
      end
      easy.set_headers
      easy
    end
    private :get_easy_object

    def response_from_easy(easy, request)
      Response.new(:code                => easy.response_code,
                   :headers             => easy.response_header,
                   :body                => easy.response_body,
                   :time                => easy.total_time_taken,
                   :start_transfer_time => easy.start_transfer_time,
                   :app_connect_time    => easy.app_connect_time,
                   :pretransfer_time    => easy.pretransfer_time,
                   :connect_time        => easy.connect_time,
                   :name_lookup_time    => easy.name_lookup_time,
                   :effective_url       => easy.effective_url,
                   :request             => request)
    end
    private :response_from_easy


  end
end
