=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element::Capabilities

# Looks for specific substrings or patterns in response bodies.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Auditable::Taint

    TAINT_OPTIONS = {
        #
        # The regular expression to match against the response body.
        #
        # Alternatively, you can use the :substring option.
        #
        regexp:    nil,

        #
        # Verify the matched string with this value when using a regexp.
        #
        match:     nil,

        #
        # The substring to look for the response body.
        #
        # Alternatively, you can use the :regexp option.
        #
        substring: nil,

        #
        # Array of patterns to ignore.
        #
        # Useful when needing to narrow down what to log without
        # having to construct overly complex match regexps.
        #
        ignore:    nil,

        #
        # Extract the longest word from each regexp and only proceed to the
        # full match only if that word is included in the response body.
        #
        # The check is case insensitive.
        #
        longest_word_optimization: false
    }

    REMARK = 'This issue was identified by a pattern but the pattern matched ' <<
            'the page\'s response body even before auditing the logged element.'

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
    #       {Platform#pick picked} from the hash based on
    #       {Element::Base#platforms applicable platforms} for the
    #       {Base#action resource} to be audited.
    # @param  [Hash]    opts
    #   Options as described in {Arachni::Module::Auditor::OPTIONS} and
    #   {TAINT_OPTIONS}.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope).
    def taint_analysis( payloads, opts = { } )
        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        # We'll have to keep track of logged issues for analysis a bit down the line.
        @logged_issues = []

        # Grab an untainted response.
        submit { |response| @untainted_response = response }

        # Perform the taint analysis.
        opts = self.class::OPTIONS.merge( TAINT_OPTIONS.merge( opts ) )
        audit( payloads, opts ) { |res, c_opts| get_matches( res, c_opts ) }

        # Go over the issues and flag them as untrusted if the pattern that
        # caused them to be logged matches the untainted response.
        http.after_run do
            @logged_issues.each do |issue|
                next if !@untainted_response.body.include?( issue.match )

                issue.verification = true
                issue.add_remark :auditor, REMARK
            end
        end
    end

    private

    # Tries to identify an issue through pattern matching.
    #
    # If a issue is found a message will be printed and the issue will be logged.
    #
    # @param  [Typhoeus::Response]  res
    # @param  [Hash]  opts
    def get_matches( res, opts )
        opts[:substring] = opts[:injected_orig] if !opts[:regexp] && !opts[:substring]

        match_patterns( opts[:regexp], method( :match_regexp_and_log ), res, opts.dup )
        match_patterns( opts[:substring], method( :match_substring_and_log ), res, opts.dup )
    end

    def match_patterns( patterns, matcher, res, opts )
        if opts[:longest_word_optimization]
            opts[:downcased_body] = res.body.downcase
        end

        case patterns
            when Regexp, String, Array
                [patterns].flatten.compact.
                    each { |pattern| matcher.call( pattern, res, opts ) }

            when Hash
                if opts[:platform] && patterns[opts[:platform]]
                    [patterns[opts[:platform]]].flatten.compact.each do |p|
                        [p].flatten.compact.
                            each { |pattern| matcher.call( pattern, res, opts ) }
                    end
                else
                    patterns.each do |platform, p|
                        dopts = opts.dup
                        dopts[:platform] = platform

                        [p].flatten.compact.
                            each { |pattern| matcher.call( pattern, res, dopts ) }
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
                            each { |pattern| matcher.call( pattern, res, dopts ) }
                    end
        end
    end

    def match_substring_and_log( substring, res, opts )
        return if substring.to_s.empty?

        if res.body.include?( substring ) && !ignore?( res, opts )
            opts[:regexp] = opts[:id] = opts[:match] = substring.dup
            @logged_issues |= @auditor.log( opts, res )
        end
    end

    def match_regexp_and_log( regexp, res, opts, untainted_response = nil )
        regexp = regexp.is_a?( Regexp ) ? regexp :
            Regexp.new( regexp.to_s, Regexp::IGNORECASE )

        if opts[:downcased_body]
            return if !opts[:downcased_body].include?( longest_word_for_regexp( regexp ) )
        end

        match_data = res.body.scan( regexp ).flatten.first.to_s

        # fairly obscure condition...pardon me...
        if ( opts[:match] && match_data == opts[:match] ) ||
           ( !opts[:match] && match_data && match_data.size > 0 )

            return if ignore?( res, opts )

            opts[:id] = opts[:match]  = opts[:match] ? opts[:match] : match_data
            opts[:regexp] = regexp

            @logged_issues |= @auditor.log( opts, res )
        end

    rescue => e
        ap e
        ap e.backtrace
    end

    def ignore?( res, opts )
        [opts[:ignore]].flatten.compact.each do |r|
            r = r.is_a?( Regexp ) ? r : Regexp.new( r.to_s, Regexp::IGNORECASE )
            return true if res.body.scan( r ).flatten.first
        end
        false
    end

    def longest_word_for_regexp( regexp )
        @@longest_word_for_regex ||= {}
        @@longest_word_for_regex[regexp.source.hash] ||=
            regexp.source.longest_word.downcase
    end

end
end
