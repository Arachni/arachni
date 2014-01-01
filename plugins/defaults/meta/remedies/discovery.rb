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
# Catches custom 404 or similar server behavior that can confuse discovery
# modules.
#
# This is relatively easy to determine since valid responses to discovery modules
# should vary wildly while custom 404 responses will have many commonalities
# every time.
#
# This is a sort of baseline implementation/anomaly detection.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::Discovery < Arachni::Plugin::Base

    # valid responses to discovery modules should vary *wildly*
    # especially considering the types of directories and files that
    # these modules look for
    #
    # on the other hand custom 404 or such responses will have many things
    # in common which makes it possible to spot them without much bother
    SIMILARITY_TOLERANCE = 0.25

    REMARK = "This issue was logged by a discovery module but " +
        "the response for the resource it identified is very similar to responses " +
        "for other resources of similar type. This is a strong indication that " +
        "the logged issue is a false positive."

    def prepare
        wait_while_framework_running
    end

    def run
        # URL path => issue array
        issues_per_path = {}

        # URL path => rdiff of response bodies
        diffs_per_path  = {}

        # URL path => size of responses
        response_size_per_path  = {}

        framework.modules.issues.each_with_index do |issue, idx|
            next if !issue.tags.includes_tags?( :discovery )

            # discovery issues only have 1 variation
            #variation = issue.variations.first

            # grab the URL path of the issue which will actually be the
            # parent of the logged page because whatever is under the parent path
            # will control the behavior under that path
            #
            # did that make any sense?
            path = File.dirname( uri_parse( issue.url ).path )

            # gathering total response sizes for issues per path
            response_size_per_path[path] ||= 0
            response_size_per_path[path] += issue.response.size

            # categorize issues per path as well
            issues_per_path[path] ||= []
            issues_per_path[path] << {
                'hash'   => issue._hash,
                'index'  => idx + 1,
                'url'    => issue.url,
                'name'   => issue.name,
            }

            # extract the static parts of the responses in order to determine
            # how much of them doesn't change between requests
            #
            # large deviations between responses are good because it means that
            # we're not dealing with some custom not-found response (or something similar)
            # as these types of responses are pretty much similar to each other
            #
            # on the other hand, valid responses will be dissimilar since the
            # discovery modules look for different things.
            diffs_per_path[path] = if !diffs_per_path[path]
                                       issue['response']
                                    else
                                        diffs_per_path[path].rdiff( issue['response'] )
                                    end
        end

        issues = []
        diffs_per_path.each_pair do |path, diff|
            # calculate the similarity ratio of the responses under the current path
            similarity = Float( diff.size * issues_per_path[path].size ) / response_size_per_path[path]

            # gotcha!
            issues |= issues_per_path[path] if similarity >= SIMILARITY_TOLERANCE
        end

        issue_digests = issues.map { |i| i['hash'] }
        framework.modules.issues.each do |issue|
            next if !issue_digests.include?( issue.digest )

            issue.add_remark :meta_analysis, REMARK

            # Requires manual verification.
            issue.verification = true
        end

        register_results( issues ) if !issues.empty?
    end

    def self.info
        {
            name:        'Discovery module response anomalies',
            description: %q{Analyzes the scan results and identifies issues logged by discovery modules
                (i.e. modules that look for certain files and folders on the server),
                while the server responses were exhibiting an anomalous factor of similarity.

                There's a good chance that these issues are false positives.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            tags:        %w(anomaly discovery file directories meta)
        }
    end

end
