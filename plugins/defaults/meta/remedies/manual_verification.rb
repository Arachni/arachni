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

#
# Gathers all issues that require manual verification into an array.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::ManualVerification < Arachni::Plugin::Base

    def prepare
        wait_while_framework_running
    end

    def run
        # will hold the hash IDs of inconclusive issues
        inconclusive = framework.audit_store.issues.map.with_index do |issue, idx|
            next if !issue.verification
            {
                'hash'   => issue.digest,
                'index'  => idx + 1,
                'url'    => issue.url,
                'name'   => issue.name,
                'var'    => issue.var,
                'elem'   => issue.elem,
                'method' => issue.method
            }
        end.compact

        register_results( inconclusive ) if !inconclusive.empty?
    end

    def self.info
        {
            name:        'Issues requiring manual verification',
            description: %q{The HTTP responses of the issues logged by this plugin exhibit a suspicious pattern
                even before any audit action has taken place -- this challenges the relevance of the audit procedure.

                Thus, these issues require manual verification.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            tags:        %w(anomaly verification meta)
        }
    end

end
