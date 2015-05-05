=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities
module Analyzable

# Looks for specific substrings or patterns in response bodies.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Taint

    TAINT_OPTIONS = {
        # The regular expression to match against the response body.
        #
        # Alternatively, you can use the :substring option.
        regexp:    nil,

        # The substring to look for the response body.
        #
        # Alternatively, you can use the :regexp option.
        substring: nil,

        # Array of patterns to ignore.
        #
        # Useful when needing to narrow down what to log without
        # having to construct overly complex match regexps.
        ignore:    nil,

        # Extract the longest word from each regexp and only proceed to the
        # full match only if that word is included in the response body.
        #
        # The check is case insensitive.
        longest_word_optimization: false
    }

    # Performs taint analysis and logs an issue should there be one.
    #
    # It logs an issue when:
    #
    # * `:match` == nil AND `:regexp` matches the response body
    # * `:match`` == not nil AND  `:regexp` match == `:match`
    # * `:substring`exists in the response body
    #
    # @param  [String, Array<String>, Hash{Symbol => <String, Array<String>>}]  payloads
    #   Payloads to inject, if given:
    #
    #   * {String} -- Will inject the single payload.
    #   * {Array} -- Will iterate over all payloads and inject them.
    #   * {Hash} -- Expects {Platform} (as `Symbol`s ) for keys and {Array} of
    #       `payloads` for values. The applicable `payloads` will be
    #       {Platform::Manager#pick picked} from the hash based on
    #       {Element::Capabilities::Submittable#platforms applicable platforms}
    #       for the {Element::Capabilities::Submittable#action resource} to be audited.
    # @param  [Hash]    opts
    #   Options as described in {Arachni::Check::Auditor::OPTIONS} and
    #   {TAINT_OPTIONS}.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope).
    def taint_analysis( payloads, opts = { } )
        return false if self.inputs.empty?

        if scope.out?
            print_debug 'Taint analysis: Element is out of scope,' <<
                            " skipping: #{audit_id}"
            return false
        end

        # Buffer possible issues, we'll only register them with the system once
        # we've evaluated our control response.
        @candidate_issues = []

        # Perform the taint analysis.
        opts = self.class::OPTIONS.merge( TAINT_OPTIONS.merge( opts ) )
        audit( payloads, opts ) { |response| get_matches( response ) }
    end

    private

    # Tries to identify an issue through pattern matching.
    #
    # If a issue is found a message will be printed and the issue will be logged.
    #
    # @param  [HTTP::Response]  response
    def get_matches( response )
        vector = response.request.performer
        opts   = vector.audit_options.dup
        opts[:substring] = vector.seed if !opts[:regexp] && !opts[:substring]

        match_patterns( opts[:regexp], method( :match_regexp_and_log ), response, opts.dup )
        match_patterns( opts[:substring], method( :match_substring_and_log ), response, opts.dup )
    end

    def match_patterns( patterns, matcher, response, opts )
        if opts[:longest_word_optimization]
            opts[:downcased_body] = response.body.downcase
        end

        case patterns
            when Regexp, String, Array
                [patterns].flatten.compact.
                    each { |pattern| matcher.call( pattern, response, opts ) }

            when Hash
                if opts[:platform] && patterns[opts[:platform]]
                    [patterns[opts[:platform]]].flatten.compact.each do |p|
                        [p].flatten.compact.
                            each { |pattern| matcher.call( pattern, response, opts ) }
                    end
                else
                    patterns.each do |platform, p|
                        dopts = opts.dup
                        dopts[:platform] = platform

                        [p].flatten.compact.
                            each { |pattern| matcher.call( pattern, response, dopts ) }
                    end
                end

                return if !opts[:payload_platforms]

                # Find out if there are any patterns without associated payloads
                # and match them against every payload's response.
                patterns.select { |p, _|  !opts[:payload_platforms].include?( p ) }.
                    each do |platform, p|
                        dopts = opts.dup
                        dopts[:platform] = platform

                        [p].flatten.compact.
                            each { |pattern| matcher.call( pattern, response, dopts ) }
                    end
        end
    end

    def match_substring_and_log( substring, response, opts )
        return if substring.to_s.empty?
        return if !response.body.include?( substring ) || ignore?( response, opts )

        @candidate_issues << {
            response:  response,
            platform:  opts[:platform],
            proof:     substring,
            signature: substring,
            vector:    response.request.performer
        }
        setup_verification_callbacks
    end

    def match_regexp_and_log( regexp, response, opts )
        regexp = regexp.is_a?( Regexp ) ? regexp :
            Regexp.new( regexp.to_s, Regexp::IGNORECASE )

        if opts[:downcased_body]
            return if !opts[:downcased_body].include?( longest_word_for_regexp( regexp ) )
        end

        match_data = response.body.match( regexp )
        return if !match_data

        match_data = match_data[0].to_s

        return if match_data.to_s.empty? || ignore?( response, opts )

        @candidate_issues << {
            response:  response,
            platform:  opts[:platform],
            proof:     match_data,
            signature: regexp,
            vector:    response.request.performer
        }
        setup_verification_callbacks
    end

    def ignore?( res, opts )
        [opts[:ignore]].flatten.compact.each do |r|
            r = r.is_a?( Regexp ) ? r : Regexp.new( r.to_s, Regexp::IGNORECASE )
            return true if res.body.scan( r ).flatten.first
        end
        false
    end

    def setup_verification_callbacks
        return if @setup_verification_callbacks
        @setup_verification_callbacks = true

        # Go over the issues and flag them as untrusted if the pattern that
        # caused them to be logged matches the untainted response.
        http.after_run do
            @setup_verification_callbacks = false
            next if @candidate_issues.empty?

            # Grab an untainted response.
            submit do |response|
                # Something has gone wrong, timed-out request or closed connection.
                # If we can't verify the issue bail out...
                next if response.code == 0

                while (issue = @candidate_issues.pop)
                    # If the body of the control response matches the proof
                    # of the current issue don't bother, it'll be a coincidence
                    # causing a false positive.
                    next if response.body.include?( issue[:proof] )

                    @auditor.log( issue )
                end
            end
        end
    end

    def longest_word_for_regexp( regexp )
        @@longest_word_for_regex ||= {}
        @@longest_word_for_regex[regexp.source.hash] ||=
            regexp.source.longest_word.downcase
    end

end
end
end
end
