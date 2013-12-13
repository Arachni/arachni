=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Simple cookie collector
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.6
class Arachni::Plugins::CookieCollector < Arachni::Plugin::Base

    is_distributable

    def prepare
        @cookies = []
    end

    def run
        framework.http.add_on_new_cookies do |cookies, res|
            update( cookies.inject({}) { |h, c| h.merge!( c.simple ); h }, res )
        end
    end

    def update( cookies, res )
        return if cookies.empty? || !update?( cookies )

        res_hash = res.to_h
        res_hash.delete( :body )
        res_hash.delete( :headers_string )

        @cookies << { time: Time.now, res: res_hash, cookies: cookies }
    end

    def update?( cookies )
        return true if @cookies.empty?
        cookies.each_pair { |k, v| return true if @cookies.last[:cookies][k] != v }
        false
    end

    def clean_up
        wait_while_framework_running
        register_results( @cookies )
    end

    def self.merge( results )
        results.flatten
    end

    def self.info
        {
            name:        'Cookie collector',
            description: %q{Monitors and collects cookies while establishing a timeline of changes.

                WARNING: Highly discouraged when the audit includes cookies.
                    It will log thousands of results leading to a huge report,
                    highly increased memory and CPU usage.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6'
        }
    end

end
