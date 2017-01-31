=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
         'transfer-encoding',
         'keep-alive',
         'content-disposition'
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
        http.on_complete do |response|
            next if response.scope.out?

            headers = response.headers.
                select { |name, _| !COMMON.include?( name.to_s.downcase ) }
            next if headers.empty?

            @headers_per_url[response.url].merge! headers
        end

        wait_while_framework_running

        # The merge is here to remove the default hash Proc which cannot be
        # serialized.
        register_results( {}.merge( @headers_per_url ) )
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

        {}.merge( merged )
    end

    def self.info
        {
            name:        'Uncommon headers',
            description: %q{
Intercepts HTTP responses and logs uncommon headers.

Common headers are:

%s

} % COMMON.to_a.map { |h| "* #{h}" }.join("\n"),
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.3'
        }
    end

end
