=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Options for the {BrowserCluster} and its {BrowserCluster::Worker}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

    # @return   [Bool]
    #   Screen width.
    attr_accessor :screen_width

    # @return   [Bool]
    #   Screen height.
    attr_accessor :screen_height

    set_defaults(
        pool_size:           6,
        job_timeout:         120,
        worker_time_to_live: 100,
        ignore_images:       false,
        screen_width:        1600,
        screen_height:       1200
    )

end
end
