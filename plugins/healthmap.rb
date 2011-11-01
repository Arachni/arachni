=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Generates a simple list of safe/unsafe URLs.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class HealthMap < Arachni::Plugin::Base

    include Arachni::Module::Utilities

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    def prepare
        while( @framework.running? )
            ::IO.select( nil, nil, nil, 1 )
        end

        @audit_store = @framework.audit_store( true )
    end

    def run( )

        sitemap  = @audit_store.sitemap.map{ |url| normalize( url ) }.uniq
        sitemap |= issue_urls = @audit_store.issues.map { |issue| issue.url }.uniq

        return if sitemap.size == 0

        issue = 0
        map = []
        sitemap.each {
            |url|

            next if !url

            if issue_urls.include?( url )
                map << { :unsafe => url }
                issue += 1
            else
                map << { :safe  => url }
            end
        }

        register_results( {
            :map    => map,
            :total  => map.size,
            :safe   => map.size - issue,
            :unsafe => issue,
            :issue_percentage => ( ( Float( issue ) / map.size ) * 100 ).round
        } )

    end

    def normalize( url )
        query = URI( normalize_url( url ) ).query
        return url if !query

        url.gsub( '?' + query, '' )
    end

    def self.info
        {
            :name           => 'Health map',
            :description    => %q{Generates a simple list of safe/unsafe URLs.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
        }
    end

end

end
end
