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
# Uses the libnotify library to send notifications for each discovered issue
# and a summary at the end on the scan.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Plugins::LibNotify < Arachni::Plugin::Base

    def prepare
        return if !options['for_every_issue']

        Arachni::Module::Manager.on_register_results do |issues|
            issues.each do |issue|
                notify(
                    summary: "Found #{issue.name}",
                    body:    "In #{issue.elem} variable" +
                        " '#{issue.var}' (Severity: #{issue.severity})\n" +
                        "At #{issue.url}"
                )
            end
        end
    end

    def run
        wait_while_framework_running
    end

    def clean_up
        issue_cnt = framework.audit_store.issues.size
        time      = framework.audit_store.delta_time
        url       = framework.opts.url

        notify(
           summary: "Scan finished in #{time}",
           body:    "Found #{issue_cnt} unique issues for #{url}."
        )
    end

    def notify( opts )
        Libnotify.show({
            icon_path: framework.opts.dir['gfx'] + "spider.png",
            timeout:   2.5,
            append:    true
        }.merge( opts ))
    end

    def self.gems
        [ 'libnotify' ]
    end

    def self.info
        {
            name:        'libnotify',
            description: %q{Uses the libnotify library to send notifications for each discovered issue
                and a summary at the end of the scan.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            options:     [
                 Options::Bool.new( 'for_every_issue', [false, 'Show every issue.', true] )
             ]
        }
    end

end
