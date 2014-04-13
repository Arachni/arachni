=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Plugins::UncommonHeaders < Arachni::Plugin::Base

    is_distributable

    COMMON = Set.new([
         'content-type',
         'content-length',
         'server',
         'connection',
         'accept-ranges',
         'age',
         'allow',
         'cache-control',
         'content-encoding',
         'content-language',
         'content-range',
         'date',
         'etag',
         'expires',
         'last-modified',
         'location',
         'pragma',
         'proxy-authenticate',
         'set-cookie',
         'trailer',
         'transfer-encoding'
    ])

    def prepare
        @headers_per_url = Hash.new do |h, url|
            h[url] = {}
        end
    end

    def restore( headers )
        prepare
        @headers_per_url.merge!( headers )
    end

    def suspend
        @headers_per_url
    end

    def run
        http.add_on_complete do |response|
            headers = response.headers.
                select { |name, _| !COMMON.include?( name.to_s.downcase ) }
            next if headers.empty?

            @headers_per_url[response.url].merge! headers
        end

        wait_while_framework_running
        register_results @headers_per_url
    end

    def self.merge( results )
        merged = Hash.new do |h, url|
            h[url] = {}
        end

        results.each do |headers_per_url|
            headers_per_url.each do |url, headers|
                merged[url].merge! headers
            end
        end

        merged
    end

    def self.info
        {
            name:        'Uncommon headers',
            description: %q{Intercepts HTTP responses and logs uncommon headers.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2'
        }
    end

end
