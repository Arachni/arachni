module RequestHelpers
    include Rack::Test::Methods

    def app
        Arachni::Rest::Server
    end

    def response_data
        JSON.load response.body
    rescue => e
        ap response
        raise
    end

    def pretty_response_body
        JSON.pretty_generate( response_data )
    end

    def response_body
        response.body
    end

    def response_code
        response.status
    end

    def response
        last_response
    end

    %w(get post put delete).each do |m|
        define_method m do |path, parameters = nil, headers = {}|
            super( path, (parameters.to_json if parameters), headers )
        end
    end

    extend self
end
