=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Catches custom 404 or similar server behavior that can confuse discovery
# checks.
#
# This is relatively easy to determine since valid responses to discovery checks
# should vary wildly while custom 404 responses will have many commonalities
# every time.
#
# This is a sort of baseline implementation/anomaly detection.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
class Arachni::Plugins::Discovery < Arachni::Plugin::Base

    # Valid responses to discovery checks should vary *wildly* especially
    # considering the types of directories and files that these checks look for.
    #
    # On the other hand custom 404 or such responses will have many things in
    # common which makes it possible to spot them without much bother.
    SIMILARITY_TOLERANCE = 0.25

    REMARK = 'This issue was logged by a discovery check but ' +
        'the response for the resource it identified is very similar to responses ' +
        'for other resources of similar type. This is a strong indication that ' +
        'the logged issue is a false positive.'

    def prepare
        wait_while_framework_running
    end

    def run
        # URL path => Issue hashes.
        issue_hashes_per_path = {}

        # URL path => rdiff of response bodies.
        diffs_per_path  = {}

        # URL path => size of response bodies.
        response_size_per_path  = {}

        framework.checks.issues.each do |issue|
            next if !issue.tags.includes_tags?( :discovery )

            # We'll do this per path since 404 handlers and such operate per
            # directory...usually...probably...hopefully.
            path = File.dirname( uri_parse( issue.vector.action ).path )

            # Gather total response sizes per path.
            response_size_per_path[path] ||= 0
            response_size_per_path[path]  += issue.response.body.size

            # Categorize issues per path as well.
            issue_hashes_per_path[path] ||= []
            issue_hashes_per_path[path] << issue.hash

            # Extract the static parts of the responses in order to determine
            # how much of them doesn't change between requests.
            #
            # Large deviations between responses are good because it means that
            # we're not dealing with some custom not-found response (or something
            # similar) as these types of responses stay pretty similar.
            #
            # On the other hand, valid responses will be dissimilar since the
            # discovery checks look for different things.
            diffs_per_path[path] = !diffs_per_path[path] ?
                issue.response.body : diffs_per_path[path].rdiff( issue.response.body )
        end

        untrusted_issue_hashes = Set.new
        diffs_per_path.each_pair do |path, diff|
            # calculate the similarity ratio of the responses under the current path
            similarity = Float( diff.size * issue_hashes_per_path[path].size ) /
                response_size_per_path[path]

            next if similarity < SIMILARITY_TOLERANCE

            # Gotcha!
            untrusted_issue_hashes |= issue_hashes_per_path[path]
        end

        framework.checks.issues.each do |issue|
            next if !untrusted_issue_hashes.include?( issue.hash )

            issue.add_remark :meta_analysis, REMARK

            # Requires manual verification.
            issue.trusted = false
        end
    end

    def self.info
        {
            name:        'Discovery-check response anomalies',
            description: %q{Analyzes the scan results and identifies issues logged by discovery checks
                (i.e. checks that look for certain files and folders on the server),
                while the server responses were exhibiting an anomalous factor of similarity.

                There's a good chance that these issues are false positives.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            tags:        %w(anomaly discovery file directories meta)
        }
    end

end
