=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Plugins

#
# Generates a simple list of safe/unsafe URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HealthMap < Arachni::Plugin::Base

    include Arachni::Module::Utilities

    def prepare
        wait_while_framework_running
        @audit_store = @framework.audit_store( true )
    end

    def run
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

    def self.distributable?
        true
    end

    def self.merge( results )
        merged = {
            :map    => [],
            :total  => 0,
            :safe   => 0,
            :unsafe => 0,
            :issue_percentage => 0
        }

        results.each {
            |healthmap|
            merged[:map]    |= healthmap[:map]
            merged[:total]  += healthmap[:total]
            merged[:safe]   += healthmap[:safe]
            merged[:unsafe] += healthmap[:unsafe]
        }
        merged[:issue_percentage] = ( ( Float( merged[:unsafe] ) / merged[:total] ) * 100 ).round
        return merged
    end


    def self.info
        {
            :name           => 'Health map',
            :description    => %q{Generates a simple list of safe/unsafe URLs.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1',
        }
    end

end

end
end
