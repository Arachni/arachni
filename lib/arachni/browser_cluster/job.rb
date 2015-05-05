=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'job/result'

module Arachni
class BrowserCluster

# Represents a job to be passed to the {BrowserCluster#queue} for deferred
# execution.
#
# @abstract
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Job

    # {Job} error namespace.
    #
    # All {Job} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < BrowserCluster::Error

        # Raised when a finished {Job} is {BrowserCluster#queue queued}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class AlreadyDone < Error
        end
    end

    # @return   [Worker]
    #   Browser to use in order to perform the relevant {#run task} -- set by
    #   {Worker#run_job} via {#configure_and_run}.
    attr_reader :browser

    # @return   [Job]
    #   Forwarder [Job] in case `self` is a result of a forward operation.
    #
    # @see #forward
    # @see #forward_as
    attr_accessor :forwarder

    # @param    [Hash]  options
    def initialize( options = {} )
        @options      = options.dup
        @options[:id] = @id = options.delete(:id) || increment_id

        options.each { |k, v| options[k] = send( "#{k}=", v ) }
    end

    # @note The following resources will be available at the time of execution:
    #
    #       * {#browser}
    #
    # Encapsulates the job payload.
    #
    # @abstract
    def run
    end

    # @return   [Bool]
    #   `true` if this job never ends, `false` otherwise.
    #
    # @see #never_ending
    def never_ending?
        !!@never_ending
    end

    # @return   [Bool]
    #   `true` if this job never ends, `false` otherwise.
    def never_ending=( bool )
        @options[:never_ending] = bool
        @never_ending = bool
    end

    # Configures the job with the given resources, {#run runs} the payload
    # and then removes the assigned resources.
    #
    # @param    [Worker]  browser
    #   {#browser Browser} to use in order to perform the relevant task -- set
    #   by {BrowserCluster::Worker#run_job}.
    def configure_and_run( browser )
        set_resources( browser )
        run
    ensure
        remove_resources
    end

    # Forwards the {Result resulting} `data` to the
    # {BrowserCluster#handle_job_result browser cluster} which then forwards
    # it to the entity that {BrowserCluster#queue queued} the job.
    #
    # The result type will be the closest {Result} class to the {Job} type.
    # If the job is of type `MyJob`, `MyJob::Result` will be used, the default
    # if {Result}.
    #
    # @param    [Hash]  data
    #   Used to initialize the {Result}.
    def save_result( data )
        browser.master.handle_job_result(
            self.class::Result.new( data.merge( job: self.clean_copy ) )
        )
        nil
    end

    # @return   [Job]
    #   {#dup Copy} of `self` with any resources set by {#configure_and_run}
    #   removed.
    def clean_copy
        dup.tap { |j| j.remove_resources }
    end

    # @return   [Job]
    #   Copy of `self`
    def dup
        self.class.new add_id( @options )
    end

    # @param    [Hash]  options
    #   See {#initialize}.
    #
    # @return   [Job]
    #   Re-used request (mainly its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward( options = {} )
        self.class.new forward_options( options )
    end

    # @param    [Job]  job_type
    #   Job class under {Jobs}.
    # @param    [Hash]  options
    #   Initialization options for `job_type`.
    #
    # @return   [Job]
    #   Forwarded request (preserving its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward_as( job_type, options = {} )
        job_type.new forward_options( options )
    end

    # @return   [Integer]
    #   ID, used by the {BrowserCluster}, to tie requests to callbacks.
    def id
        @id
    end

    def hash
        @options.hash
    end

    def ==( other )
        hash == other.hash
    end

    protected

    def remove_resources
        @browser = nil
    end

    private

    def forward_options( options )
        add_id( options ).merge(
            never_ending: never_ending?,
            forwarder:    self.clean_copy
        )
    end

    def add_id( options )
        options.merge( id: @id )
    end

    def set_resources( browser )
        @browser = browser
    end

    # Increments the {#id} upon {#initialize initialization}.
    #
    # @return   [Integer]
    def increment_id
        @@id ||= 0
        @@id += 1
    end

end

end
end
