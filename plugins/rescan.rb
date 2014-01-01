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

#
# Allows users to skip the crawling phase by extracting paths discovered
# by a previous scan.
#
# It basically sets the 'restrict_paths' framework option to the sitemap of
# a previous report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::ReScan < Arachni::Plugin::Base

    def prepare
        framework.pause
        print_status "System paused."
    end

    def run
        framework.opts.restrict_paths = Arachni::AuditStore.load( options['afr'] ).sitemap
        print_status "Found #{framework.opts.restrict_paths.size} paths."
    end

    def clean_up
        framework.resume
        print_status "System resumed."
    end

    def self.info
        {
            name:        'ReScan',
            description: %q{It uses the AFR report of a previous scan to
                extract the sitemap in order to avoid a redundant crawl.
            },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            options:     [
                Options::Path.new( 'afr', [true, 'Path to the AFR report.'] )
            ]
        }
    end

end
