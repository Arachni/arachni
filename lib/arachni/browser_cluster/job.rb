=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'job/result'

module Arachni
class BrowserCluster

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Job

    class <<self
        def increment_id
            @id ||= 0
            @id += 1
        end
    end

    # @param    [Hash]  options
    def initialize( options = {} )
        @id = options.delete(:id) || self.class.increment_id
    end

    # @param    [Hash]  options See {#initialize}.
    # @return   [Job]
    #   Re-used request (mainly its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward( options = {} )
        self.class.new options.merge( id: @id )
    end

    # @param    [Job]  job_type Job class under {Jobs}.
    # @param    [Hash]  options Initialization options for `job_type`.
    # @return   [Job]
    #   Forwarded request (preserving its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward_as( job_type, options = {} )
        job_type.new options.merge( id: @id )
    end

    # @return   [Integer]
    #   ID, used by the {BrowserCluster}, to tie requests to callbacks.
    def id
        @id
    end

end

end
end
