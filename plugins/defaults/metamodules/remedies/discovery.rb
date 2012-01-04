=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Catches custom 404 or similar server behavior that can confuse discovery
# modules.
#
# This is relatively easy to determine since valid responses to discovery modules
# should vary wildly while custom 404 responses will have many comonalities
# every time.
#
# This is a sort of baseline implementation/anomaly detection.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Discovery < Arachni::Plugin::Base

    include Arachni::Module::Utilities

    # look for issues containing the following tags
    TAGS = [ [ 'file', 'discovery' ], [ 'directory', 'discovery' ] ]

    # valid responses to discovery modules should vary *wildly*
    # especially considereing the types of directories and files that
    # these modules look for
    #
    # on the other hand custom 404 or such responses will have many things
    # in common which makes it possible to spot them without much bother
    SIMILARITY_TOLERANCE = 0.25

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

        on_relevant_issues {
            |issue, idx|

            # discovery issues only have 1 variation
            variation = issue.variations.first

            # grab the URL path of the issue which will actually be the
            # parent of the logged page because whatever is under the parent path
            # will control the behavior under that path
            #
            # did that make any sense?
            path = File.dirname( URI( normalize_url( variation['url'] ) ).path )

            # gathering total response sizes for issues per path
            response_size_per_path[path] ||= 0
            response_size_per_path[path] += variation['response'].size

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
            if !diffs_per_path[path]
                diffs_per_path[path] = variation['response']
            else
                diffs_per_path[path] = diffs_per_path[path].rdiff( variation['response'] )
            end
        }

        issues = []
        diffs_per_path.each_pair {
            |path, diff|

            # calculate the similarity factor of the responses under the current path
            similarity = Float( diff.size * issues_per_path[path].size ) / response_size_per_path[path]

            # gotcha!
            if similarity >= SIMILARITY_TOLERANCE
                issues |= issues_per_path[path]
            end
        }

        register_results( issues ) if !issues.empty?
    end

    #
    # Passes each issue that was logged by a discovery module to the block.
    #
    # @param    [Proc]   &block
    #
    def on_relevant_issues( &block )
        @framework.audit_store.issues.each_with_index {
            |issue, idx|

            if includes_tags?( issue.tags )
                block.call( issue, idx )
            end
        }
    end

    #
    # Checks if 'tags' contain any item in {TAGS}
    #
    # @param    [Array]     tags
    #
    # @return   [Bool]
    #
    def includes_tags?( tags )
        TAGS.each {
            |tag_pair|
            intersection = (tags & tag_pair)
            return true if intersection && (intersection.size  == tag_pair.size)
        }
        return false
    end

    def self.info
        {
            :name           => 'Discovery module response anomalies',
            :description    => %q{Analyzes the scan results and identifies issues logged by discovery modules
                (i.e. modules that look for certain files and folders on the server),
                while the server responses were exhibiting an anomalous factor of similarity.

                There's a good chance that these issues are false positives.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1',
            :tags           => [ 'anomaly' , 'discovery', 'file', 'directories', 'meta']
        }
    end

end

end
end
