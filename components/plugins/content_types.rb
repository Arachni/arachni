=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Logs content-types of all server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::ContentTypes < Arachni::Plugin::Base

    is_distributable

    def prepare
        @results = {}
        @logged  = Arachni::Support::LookUp::HashSet.new
    end

    def restore( data )
        @results = data[:results]
        @logged  = data[:logged]
    end

    def suspend
        { results: @results, logged: @logged }
    end

    def run
        http.on_complete do |response|
            next if skip?( response )

            type = response.headers.content_type
            type = type.join( ' - ' ) if type.is_a?( Array )

            @results[type] ||= []
            @results[type] << {
                'url'        => response.url,
                'method'     => response.request.method.to_s.upcase,
                'parameters' => response.request.parameters
            }

            log( response )
        end
    end

    def skip?( response )
        response.scope.out? || logged?( response ) ||
            response.headers.content_type.to_s.empty? || !log?( response )
    end

    def log?( response )
        @exclude ||= Regexp.new( options[:exclude] )
        options[:exclude].empty? ||
            !response.headers.content_type.to_s.match( @exclude )
    end

    def logged?( response )
        @logged.include?( log_id( response ) )
    end

    def log( response )
        @logged << log_id( response )
    end

    def log_id( response )
        response.request.method.to_s.upcase + response.url
    end

    def clean_up
        wait_while_framework_running
        register_results( @results )
    end

    def self.merge( results )
        merged = {}

        results.each do |result|
            result.each do |type, val|
                merged[type] ||= []
                merged[type] |= val
            end
        end

        merged
    end

    def self.info
        {
            name:        'Content-types',
            description: %q{
Logs content-types of server responses.

It can help you categorize and identify publicly available file-types which in
turn can help you identify accidentally leaked files.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.7',
            options:     [
                Options::String.new( :exclude,
                    description: 'Exclude content-types that match this regular expression.',
                    default:     'text'
                )
            ]
        }
    end

end
