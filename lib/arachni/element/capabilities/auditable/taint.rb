=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni::Element::Capabilities

#
# Looks for specific substrings or patterns in response bodies.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
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
        ignore:    nil
    }

    REMARK = 'This issue was identified by a pattern but the pattern matched ' <<
            'the page\'s response body even before auditing the logged element.'

    #
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
    #
    def taint_analysis( payloads, opts = { } )
        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

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
        opts = response.request.performer.audit_options.dup
        opts[:substring] = opts[:injected_orig] if !opts[:regexp] && !opts[:substring]

        match_patterns( opts[:regexp], method( :match_regexp_and_log ), response, opts.dup )
        match_patterns( opts[:substring], method( :match_substring_and_log ), response, opts.dup )
    end

    def match_patterns( patterns, matcher, response, opts )
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

    def match_substring_and_log( substring, res, opts )
        return if substring.to_s.empty?

        opts[:verification] = @auditor.page && @auditor.page.body &&
            @auditor.page.body.include?( substring )

        opts[:remarks] = { auditor: [REMARK] } if opts[:verification]

        if res.body.include?( substring ) && !ignore?( res, opts )
            opts[:regexp] = opts[:id] = opts[:match] = substring.dup
            @auditor.log( opts, res )
        end
    end

    def match_regexp_and_log( regexp, res, opts )
        regexp = regexp.is_a?( Regexp ) ? regexp :
            Regexp.new( regexp.to_s, Regexp::IGNORECASE )

        match_data = res.body.scan( regexp ).flatten.first.to_s

        # An annoying encoding exception may be thrown when matching the regexp.
        opts[:verification] = (@auditor.page && @auditor.page.body.to_s =~ regexp) rescue false

        opts[:remarks] = { auditor: [REMARK] } if opts[:verification]

        # fairly obscure condition...pardon me...
        if ( opts[:match] && match_data == opts[:match] ) ||
           ( !opts[:match] && match_data && match_data.size > 0 )

            return if ignore?( res, opts )

            opts[:id] = opts[:match]  = opts[:match] ? opts[:match] : match_data
            opts[:regexp] = regexp

            @auditor.log( opts, res )
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

end
end
