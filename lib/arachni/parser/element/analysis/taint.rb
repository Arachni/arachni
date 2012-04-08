=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Looks for specific substrings or patterns in response bodies.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Arachni::Parser::Element::Analysis::Taint

    TAINT_OPTIONS = {
        #
        # The regular expression to match against the response body.
        #
        # Alternatively, you can use the :substring option.
        #
        :regexp   => nil,

        #
        # Verify the matched string with this value when using a regexp.
        #
        :match    => nil,

        #
        # The substring to look for the response body.
        #
        # Alternatively, you can use the :regexp option.
        #
        :substring => nil
    }

    #
    # Performs taint analysis and logs an issue should there be one.
    #
    # It logs an issue when:
    # * _:match_ == nil AND _:regexp_ matches the response body
    # * _:match_ == not nil AND  _:regexp_ match == _:match_
    # * _:substring_ exists in the response body
    #
    # @param  [String]  seed      the string to be injected
    # @param  [Hash]    opts      options as described in {Arachni::Module::Auditor::OPTIONS} and {TAINT_OPTIONS}
    # @param  [Block]   &block    block to be passed the:
    #                               * HTTP response
    #                               * name of the input vector
    #                               * updated opts
    #                               The block will be called as soon as the HTTP response is received.
    #
    def taint_analysis( seed, opts = { } )
        opts = self.class::OPTIONS.merge( TAINT_OPTIONS.merge( opts ) )
        opts[:substring] = seed if !opts[:regexp] && !opts[:substring]
        audit( seed, opts ) { |res, opts| get_matches( res, opts ) }
    end

    private

    #
    # Tries to identify an issue through regexp pattern matching.
    #
    # If a issue is found a message will be printed and a hash
    # will be returned describing the conditions under which
    # the issue was discovered.
    #
    # @param  [Typhoeus::Response]
    # @param  [Hash]  opts
    #
    # @return  [Hash]
    #
    def get_matches( res, opts )
        [opts[:regexp]].flatten.compact.each { |regexp| match_regexp_and_log( regexp, res, opts ) }
        [opts[:substring]].flatten.compact.each { |substring| match_substring_and_log( substring, res, opts ) }
    end

    def match_substring_and_log( substring, res, opts )
        verification = false

        # an annoying encoding exception may be thrown by scan()
        # the sob started occuring again....
        begin
            verification = true if @auditor.page.html.substring?( substring )
        rescue
        end

        if res.body.substring?( substring )
           opts[:regexp] = opts[:id] = opts[:match]  = substring.clone
           @auditor.log( opts, res )
        end
    end

    def match_regexp_and_log( regexp, res, opts )
        regexp = regexp.is_a?( Regexp ) ? regexp :
            Regexp.new( regexp.to_s, Regexp::IGNORECASE )

        match_data = res.body.scan( regexp )[0]
        match_data = match_data.to_s

        verification = false

        # an annoying encoding exception may be thrown by scan()
        # the sob started occuring again....
        begin
            opts[:verification] = true if @auditor.page.html.scan( regexp )[0]
        rescue
        end

        # fairly obscure condition...pardon me...
        if ( opts[:match] && match_data == opts[:match] ) ||
           ( !opts[:match] && match_data && match_data.size > 0 )

           opts[:id] = opts[:match]  = opts[:match] ? opts[:match] : match_data
           opts[:regexp] = regexp

           @auditor.log( opts, res )
        end
    end

end
