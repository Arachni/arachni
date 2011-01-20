require 'typhoeus'

module Typhoeus
  class Response
    attr_reader :start_transfer_time,
                :app_connect_time, :pretransfer_time,
                :connect_time, :name_lookup_time

    def initialize(params = {})
      @code                  = params[:code]
      @status_message        = params[:status_message]
      @http_version          = params[:http_version]
      @headers               = params[:headers] || ''
      @body                  = params[:body]
      @time                  = params[:time]
      @requested_url         = params[:requested_url]
      @requested_http_method = params[:requested_http_method]
      @start_time            = params[:start_time]
      @start_transfer_time   = params[:start_transfer_time]
      @app_connect_time      = params[:app_connect_time]
      @pretransfer_time      = params[:pretransfer_time]
      @connect_time          = params[:connect_time]
      @name_lookup_time      = params[:name_lookup_time]
      @request               = params[:request]
      @effective_url         = params[:effective_url]
      @mock                  = params[:mock] || false  # default
      @headers_hash          = NormalizedHeaderHash.new(params[:headers_hash]) if params[:headers_hash]
    end

    #
    # Converts obj to hash
    #
    # @param    [Object]  obj    instance of an object
    #
    # @return    [Hash]
    #
    def to_hash
        hash = Hash.new
        instance_variables.each {
            |var|
            key       = var.to_s.gsub( /@/, '' )
            hash[key] = instance_variable_get( var )

        }

        hash['headers_hash'] = {}
        headers_hash.each_pair {
            |k, v|
            hash['headers_hash'][k] = v
        }

        hash.delete( 'request' )

        return hash
    end


  end
end
