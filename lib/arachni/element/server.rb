=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents a remote server, mainly for checking for and logging remote resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Server < Base
    include Capabilities::WithAuditor

    # Used to determine how different a resource should be in order to be sent
    # to the {Trainer#push}.
    #
    # Ideally, all identified resources should be analyzed by the {Trainer} but
    # there can be cases where unreliable custom-4o4 signatures lead to FPs and
    # feeding FPs to the system can create an infinite loop.
    SIMILARITY_TOLERANCE = 0.25

    def initialize( url )
        super url: url
        @initialization_options = url

        # Holds possible issue responses, they'll be logged after #analyze
        # goes over them.
        @candidates = []

        # Process responses that may point to issues.
        http.after_run( &method(:analyze) )
    end

    # @note Ignores custom 404 responses.
    #
    # Logs a remote file or directory if it exists.
    #
    # @param    [String]    url
    #   Resource to check.
    # @param    [Bool]      silent
    #   If `false`, a message will be printed to stdout containing the status of
    #   the operation.
    # @param    [Proc]      block
    #   Called if the file exists, just before logging the issue, and is passed
    #   the HTTP response.
    #
    # @return   [Object]
    #   * `nil` if no URL was provided.
    #   * `false` if the request couldn't be fired.
    #   * `true` if everything went fine.
    #
    # @see #remote_file_exist?
    def log_remote_file_if_exists( url, silent = false, &block )
        return nil if !url

        auditor.print_status( "Checking for #{url}" ) if !silent
        remote_file_exist?( url ) do |bool, response|
            auditor.print_status( "Analyzing response for: #{url}" ) if !silent
            next if !bool

            @candidates << [response, block]
        end
        true
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    # @note Ignores custom 404 responses.
    #
    # Checks whether or not a remote resource exists.
    #
    # @param    [String]    url
    #   Resource to check.
    # @param    [Block] block
    #   Block to be passed  `true` if the resource exists or `false` otherwise
    #   and the response for the resource check.
    def remote_file_exist?( url, &block )
        if http.needs_custom_404_check?( url )
            http.get( url, performer: self ) do |r|
                if r.code == 200
                    http.custom_404?( r ) { |bool| block.call( !bool, r ) }
                else
                    block.call( false, r )
                end
            end
        else
            http.request( url, method: :head, performer: self ) do |response|
                block.call( response.code == 200, response )
            end
        end

        nil
    end
    alias :remote_file_exists? :remote_file_exist?

    def http
        Arachni::HTTP::Client
    end

    private

    def analyze
        return if @candidates.empty?

        if @candidates.size == 1
            response, block = @candidates.first

            # Single issue, not enough confidence to use it for training, err
            # on the side of caution.
            log response, false, &block

            return
        end

        baseline = nil
        size_sum = 0
        @candidates.each.with_index do |(response, _), i|
            size_sum += response.body.size

            # Treat all responses as if they were for the same resource and
            # create a baseline from their bodies.
            #
            # Large deviations between responses are good because it means that
            # we're not dealing with some custom-404 response (or something
            # similar) as these types of responses stay pretty close.
            baseline = baseline ? baseline.rdiff( response.body ) : response.body
        end

        similarity = Float( baseline.size * @candidates.size ) / size_sum

        # Don't train if the responses are too similar, we may be feeding the
        # framework custom-404s and get into an infinite loop.
        train = similarity < SIMILARITY_TOLERANCE

        @candidates.each do |response, block|
            log response, train, &block
        end

    ensure
        @candidates.clear
    end

    def log( response, train = true, &block )
        block.call( response ) if block_given?

        auditor.log_remote_file( response )

        return if !train

        # Use the newly identified resource to increase the scan scope.
        auditor.framework.trainer.push( response )
    end

end
end
