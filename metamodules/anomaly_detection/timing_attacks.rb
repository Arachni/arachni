=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module MetaModules

#
# Provides a notice for issues uncovered by timing attacks when the affected audited
# pages returned unusually high response times to begin with.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class TimingAttacks < Base

    include Arachni::Module::Utilities

    # look for issue by tag name
    TAG            = 'timing'

    # response times of a page must be greater or equal to this
    # in order to be considered
    TIME_THRESHOLD = 0.6

    def initialize( framework )
        @framework = framework
        @http = framework.http

        @times = {}
        @counter = {}
    end

    def pre
        # run for each response as it arrives
        @http.add_on_complete {
            |res|

            # we don't care about non OK responses
            next if res.code != 200

            path = URI( normalize_url( res.effective_url ) ).path
            path = '/' if path.empty?
            @counter[path] ||= @times[path] ||= 0

            # add up all request times for a specific path
            @times[path] += res.start_transfer_time

            # add up all requests for each path
            @counter[path] += 1
        }
    end

    def post

        avg = get_avg

        # will hold the hash IDs of inconclusive issues
        inconclusive = []
        @framework.audit_store.issues.each_with_index {
            |issue, idx|
            if issue.tags && issue.tags.include?( TAG ) &&
                avg[ URI( normalize_url( issue.url ) ).path ] >= TIME_THRESHOLD

                inconclusive << {
                    'hash'   => issue._hash,
                    'index'  => idx + 1,
                    'url'    => issue.url,
                    'name'   => issue.name,
                    'var'    => issue.var,
                    'elem'   => issue.elem,
                    'method' => issue.method
                }
            end
        }

        return inconclusive
    end

    def get_avg
        avg ={}

        # calculate average request time for each path
        @times.each_pair {
            |path, time|
            avg[path] = time / @counter[path]
        }

        return avg
    end

    def self.info
        {
            :description    => %q{These logged issues used timing attacks.
                However, the affected web pages demonstrated an unusually high response time rendering
                these results inconclusive or (possibly) false positives.

                Pages with high response times usually include heavy-duty processing
                which makes them prime targets for Denial-of-Service attacks.

                Nomatter the case, please do look into the situation further.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
        }
    end

end

end
end
