=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

class Arachni::Plugins::SpiderHook < Arachni::Plugin::Base

    is_distributable

    def prepare
        framework.pause
        @urls = []
    end

    def run
        spider.on_each_page { |page| @urls << page.url }
    end

    def clean_up
        framework.resume
        wait_while_framework_running
        sleep 1 # emulate some latency to catch race conditions
        register_results( framework.self_url => @urls )
    end

    def self.merge( results )
        results.inject( {} ) { |h, r| h.merge!( r ); h }
    end

    def self.info
        {
            name:        'SpiderHook',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1'
        }
    end

end
