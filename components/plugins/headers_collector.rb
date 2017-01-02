=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::HeadersCollector < Arachni::Plugin::Base

    is_distributable

    def prepare
        if options[:include]
            @include_pattern = Regexp.new( options[:include] )
        end

        if options[:exclude]
            @exclude_pattern = Regexp.new( options[:exclude] )
        end

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

            headers = response.headers.select { |name, _| collect?( name.to_s.downcase ) }
            next if headers.empty?

            @headers_per_url[response.url].merge! headers
        end

        wait_while_framework_running

        # The merge is here to remove the default hash Proc which cannot be
        # serialized.
        register_results( {}.merge( @headers_per_url ) )
    end

    def collect?( name )
        return false if @exclude_pattern && @exclude_pattern =~ name

        if @include_pattern
            return @include_pattern =~ name
        end

        true
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
            name:        'Headers collector',
            description: %q{
Intercepts HTTP responses and logs headers whose name matches the specified criteria.

**NOTE**:

* Header names will be lower-case.
* If no patterns have been provided, all response headers will be logged.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            options:     [
                Options::String.new( :include,
                    description: 'Include headers whose name matches the pattern.'
                ),
                Options::String.new( :exclude,
                    description: 'Exclude headers whose name matches the pattern.'
                )
            ]
        }
    end

end
