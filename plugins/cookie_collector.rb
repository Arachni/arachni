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
# Simple cookie collector
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class CookieCollector < Arachni::Plugin::Base

    def prepare
        @cookies = []
    end

    def run
        @framework.http.add_on_new_cookies {
            |cookies, res|
            update( cookies, res )
        }
    end

    def update( cookies, res )
        return if cookies.empty? || !update?( cookies )

        res_hash = res.to_hash
        res_hash.delete( 'body' )

        @cookies << {
            :time       => Time.now,
            :res        => res_hash,
            :cookies    => cookies
        }
    end

    def update?( cookies )
        return true if @cookies.empty?

        cookies.each_pair {
            |k, v|
            return true if @cookies.last[:cookies][k] != v
        }

        return false
    end

    def clean_up
        while( @framework.running? )
            ::IO.select( nil, nil, nil, 1 )
        end

        register_results( @cookies )
    end

    def self.distributable?
        true
    end

    def self.merge( results )
        results.flatten
    end


    def self.info
        {
            :name           => 'Cookie collector',
            :description    => %q{Monitors and collects cookies while establishing a timeline of changes.

                WARNING: Highly discouraged when the audit includes cookies.
                    It will log thousands of results leading to a huge report,
                    highly increased memory and CPU usage.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.3',
        }
    end

end

end
end
