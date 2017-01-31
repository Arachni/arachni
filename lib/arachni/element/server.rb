=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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

    # Valid responses to discovery checks should vary *wildly*, especially when
    # considering the types of directories and files that these checks look for.
    #
    # On the other hand, custom-404 or such responses will have many things in
    # common which makes it possible to spot them without much bother.
    #
    # Ideally, custom-404s will be identified properly by the
    # {HTTP::Client::Dynamic404Handler} but this is here to save our ass in case
    # there's a bug or an unforeseen edge-case or something.
    #
    # Also, identified resources should be analyzed by the {Trainer} but there
    # can be cases where unreliable custom-404 signatures lead to FPs and feeding
    # FPs to the system can create an infinite loop.
    SIMILARITY_TOLERANCE = 0.25

    # Remark in case of an untrusted issue.
    REMARK = 'This issue was logged by a discovery check but ' +
        'the response for the resource it identified is very similar to responses ' +
        'for other resources of similar type. This is a strong indication that ' +
        'the logged issue is a false positive.'

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
    #   * `false` if an invalid URL was provided.
    #   * `true` if everything went fine.
    #
    # @see #remote_file_exist?
    def log_remote_file_if_exists( url, silent = false, options = {}, &block )
        # Make sure the URL is valid.
        return false if !(url.start_with?( 'http://' ) || url.start_with?( 'https://' ))

        auditor.print_status( "Checking for #{url}" ) if !silent
        remote_file_exist?( url ) do |bool, response|
            auditor.print_status( "Analyzing response for: #{url}" ) if !silent
            next if !bool

            @candidates << [response, block, options]
        end
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
    #
    # @return   [Object]
    #   * `false` if an invalid URL was provided.
    #   * `true` if everything went fine.
    def remote_file_exist?( url, &block )
        # Make sure the URL is valid.
        return false if !(url.start_with?( 'http://' ) || url.start_with?( 'https://' ))

        if http.dynamic_404_handler.needs_check?( url )

            # Don't enable fingerprinting if there's a dynamic handler, we don't
            # want to keep analyzing non existent resources.
            #
            # If a resource does exist though it will be fingerprinted down the
            # line.
            http.get( url, performer: self, fingerprint: false, follow_location: true ) do |r|
                if r.code == 200
                    http.dynamic_404_handler._404?( r ) { |bool| block.call( !bool, r ) }
                else
                    block.call( false, r )
                end
            end
        else
            http.request( url, method: :head, performer: self, follow_location: true ) do |response|
                block.call( response.code == 200, response )
            end
        end

        true
    end
    alias :remote_file_exists? :remote_file_exist?

    def http
        Arachni::HTTP::Client
    end

    def inspect
        s = "#<#{self.class} "

        if !orphan?
            s << "auditor=#{auditor.class} "
        end

        s << "url=#{url.inspect}"
        s << '>'
    end

    def self.flag_issues_as_untrusted( issue_digests )
        issue_digests.uniq.each do |digest|
            next if !(issue = Arachni::Data.issues[digest])

            issue.add_remark :meta_analysis, REMARK
            issue.trusted = false
        end
    end

    def self.flag_issues_if_untrusted( similarity, issue_digests )
        return if similarity < SIMILARITY_TOLERANCE

        flag_issues_as_untrusted( issue_digests )
    end

    private

    def analyze
        return if @candidates.empty?

        if @candidates.size == 1
            response, block, options = @candidates.first

            # Single issue, not enough confidence to use it for training, err
            # on the side of caution.
            log response, false, options, &block

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

        issue_digests = []
        @candidates.each do |response, block, options|
            issue_digests << log( response, train, options, &block ).digest
        end

        return if train

        self.class.flag_issues_as_untrusted( issue_digests )
    ensure
        @candidates.clear
    end

    def log( response, train = true, options = {}, &block )
        block.call( response ) if block_given?

        issue = auditor.log_remote_file( response, false, options )

        return issue if !train

        # Use the newly identified resource to increase the scan scope.
        auditor.framework.trainer.push( response )

        issue
    end

end
end
