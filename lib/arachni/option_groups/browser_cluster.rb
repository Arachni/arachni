=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::OptionGroups

# Options for the {BrowserCluster} and its {BrowserCluster::Worker}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserCluster < Arachni::OptionGroup

    # @return   [Integer]
    #   Amount of {BrowserCluster::Worker} to keep in the pool and put to work.
    attr_accessor :pool_size

    # @return   [Integer]
    #   Maximum allowed time for jobs in seconds.
    attr_accessor :job_timeout

    # @return   [Integer]
    #   Re-spawn the browser every {#worker_time_to_live} jobs.
    attr_accessor :worker_time_to_live

    # @return   [Bool]
    #   Should the browser's avoid loading images?
    attr_accessor :ignore_images

    set_defaults(
        pool_size:           6,
        job_timeout:         50,
        worker_time_to_live: 100,
        ignore_images:       false
    )

end
end
