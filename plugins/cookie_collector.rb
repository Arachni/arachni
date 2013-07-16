=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Simple cookie collector
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
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
        res_hash.delete( 'body' )

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
            :name => 'Cookie collector',
            :description => %q{Monitors and collects cookies while establishing a timeline of changes.

                WARNING: Highly discouraged when the audit includes cookies.
                    It will log thousands of results leading to a huge report,
                    highly increased memory and CPU usage.},
            :author => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version => '0.1.5'
        }
    end

end
