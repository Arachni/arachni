=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Options for the {BrowserCluster} and its {BrowserCluster::Worker}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class BrowserCluster < Arachni::OptionGroup

    # @return   [Hash]
    #   Data to be set in the browser's `localStorage`.
    attr_accessor :local_storage

    # @return   [Hash<Regexp,String>]
    #   When the page URL matched the key `Regexp`, wait until the `String` CSS
    #   selector in the value matches an element.
    attr_accessor :wait_for_elements

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
        local_storage:       {},
        wait_for_elements:   {},
        pool_size:           6,
        # Not actually a timeout for the job anymore, sets a timeout for Selenium
        # communication HTTP requests.
        # Name hijacked for compatibility, but should probably change in the
        # future.
        job_timeout:         10,
        worker_time_to_live: 100,
        ignore_images:       false,
        screen_width:        1600,
        screen_height:       1200
    )

    def local_storage=( data )
        data ||= {}

        if !data.is_a?( Hash )
            fail ArgumentError, "Expected data to be Hash, got #{data.class} instead."
        end

        @local_storage = data
    end

    def css_to_wait_for( url )
        wait_for_elements.map do |pattern, css|
            next if !(url =~ pattern)
            css
        end.compact
    end

    def wait_for_elements=( rules )
        return @wait_for_elements = defaults[:wait_for_elements].dup if !rules

        @wait_for_elements = rules.inject({}) do |h, (regexp, value)|
            regexp = regexp.is_a?( Regexp ) ?
                regexp :
                Regexp.new( regexp.to_s, Regexp::IGNORECASE )
            h.merge!( regexp => value )
            h
        end
    end

    def to_rpc_data
        d = super

        d['wait_for_elements'] = d['wait_for_elements'].dup

        d['wait_for_elements'].dup.each do |k, v|
            d['wait_for_elements'][k.source] = d['wait_for_elements'].delete(k)
        end

        d
    end

end
end
