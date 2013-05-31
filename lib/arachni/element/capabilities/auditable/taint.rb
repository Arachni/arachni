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
    def taint_analysis( payloads, opts = { } )
        opts = self.class::OPTIONS.merge( TAINT_OPTIONS.merge( opts ) )
        audit( payloads, opts ) { |res, c_opts| get_matches( res, c_opts ) }
    end

    private

    #
    # Tries to identify an issue through pattern matching.
    #
    # If a issue is found a message will be printed and the issue will be logged.
    #
    # @param  [Typhoeus::Response]  res
    # @param  [Hash]  opts
    #
    def get_matches( res, opts )
        opts[:substring] = opts[:injected_orig] if !opts[:regexp] && !opts[:substring]

        [opts[:regexp]].flatten.compact.each { |regexp| match_regexp_and_log( regexp, res, opts ) }
        [opts[:substring]].flatten.compact.each { |substring| match_substring_and_log( substring, res, opts ) }
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
