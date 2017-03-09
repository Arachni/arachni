=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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
module Signature

    SIGNATURE_CACHE   = {
        match: Support::Cache::LeastRecentlyPushed.new( 10_000 )
    }

    SIGNATURE_OPTIONS = {
        # The signatures to look for in each line of the response body,
        # if `Regexp` it will be matched against it, if `String` it'll be used
        # as a needle.
        #
        # Multi-line Regexp is not supported.
        signatures: [],

        # Array of signatures to ignore.
        #
        # Useful when needing to narrow down what to log without having to
        # construct overly complex signatures.
        ignore:     []
    }

    FILE_SIGNATURES = {
        'environ'  => proc do |response|
            next if !response.body.include?( 'DOCUMENT_ROOT=' )
            /DOCUMENT_ROOT=.*HTTP_USER_AGENT=/
        end,
        'passwd'   => proc do |response|
            if response.body.include?( 'bin/' )
                /:.+:\d+:\d+:.+:[0-9a-zA-Z\/]+/

            # Response may have encoded chars as HTML entities.
            elsif response.body.include?( 'bin&#x2f;' ) && response.body.include?( '&#x3a;' )
                /&#x3a;.+&#x3a;\d+&#x3a;\d+&#x3a;.+&#x3a;[0-9a-zA-Z&#;]+/
            end
        end,
        'boot.ini' => '[boot loader]',
        'win.ini'  => '[extensions]',
        'web.xml'  => '<web-app'
    }

    FILE_SIGNATURES_PER_PLATFORM = {
        unix:   [
            FILE_SIGNATURES['environ'],
            FILE_SIGNATURES['passwd']
        ],
        windows: [
            FILE_SIGNATURES['boot.ini'],
            FILE_SIGNATURES['win.ini']
        ],
        java:    [
            FILE_SIGNATURES['web.xml']
        ]
    }

    SOURCE_CODE_SIGNATURES_PER_PLATFORM = {
        php:  [
            '<?php'
        ],

        # No need to optimize the following with procs, OR'ed Regexps perform
        # better than multiple substring checks, so long as the Regexp parts are
        # fairly simple.

        java: [
            /<%|<%=|<%@\s+page|<%@\s+include|<%--|import\s+javax.servlet|
                import\s+java.io|import=['"]java.io|request\.getParameterValues\(|
                response\.setHeader|response\.setIntHeader\(/
        ],
        asp:  [
            /<%|Response\.Write|Request\.Form|Request\.QueryString|
                Response\.Flush|Session\.SessionID|Session\.Timeout|
                Server\.CreateObject|Server\.MapPath/
        ]
    }

    LINE_BUFFER_SIZE = 1_000

    # Performs signatures analysis and logs an issue, should there be one.
    #
    # It logs an issue when:
    #
    # * `:match` == nil AND `:regexp` matches the response body
    # * `:match` != nil AND  `:regexp` match == `:match`
    # * `:substring` exists in the response body
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
    #   Options as described in {Arachni::Element::Auditable::OPTIONS} and
    #   {SIGNATURE_OPTIONS}.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope).
    def signature_analysis( payloads, opts = { } )
        return false if self.inputs.empty?

        if scope.out?
            print_debug 'Signature analysis: Element is out of scope,' <<
                            " skipping: #{audit_id}"
            return false
        end

        # Buffer possible issues, we'll only register them with the system once
        # we've evaluated our control response.
        @candidate_issues = []

        opts = self.class::OPTIONS.merge( SIGNATURE_OPTIONS.merge( opts ) )

        fail_if_signatures_invalid( opts[:signatures] )

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

        if !opts[:signatures].is_a?( Array ) && !opts[:signatures].is_a?( Hash )
            opts[:signatures] = [opts[:signatures]]
        end

        opts[:signatures] = [vector.seed] if opts[:signatures].empty?

        find_signatures( opts[:signatures], response, opts.dup )
    end
    public :get_matches

    def fail_if_signatures_invalid( signatures )
        case signatures
            when Regexp
                if (signatures.options & Regexp::MULTILINE) == Regexp::MULTILINE
                    fail ArgumentError,
                         'Multi-line regular expressions are not supported.'
                end

            when Array
                signatures.each { |s| fail_if_signatures_invalid s }

            when Hash
                fail_if_signatures_invalid signatures.values
        end
    end

    def find_signatures( signatures, response, opts )
        k = [signatures, response.body]
        return if SIGNATURE_CACHE[:match][k] == false

        case signatures
            when Regexp, String, Array
                [signatures].flatten.compact.each do |signature|
                    res = find_signature( signature, response, opts )
                    SIGNATURE_CACHE[:match][k] ||= !!res
                end

            when Hash
                if opts[:platform] && signatures[opts[:platform]]
                    [signatures[opts[:platform]]].flatten.compact.each do |p|
                        [p].flatten.compact.each do |signature|
                            res = find_signature( signature, response, opts )
                            SIGNATURE_CACHE[:match][k] ||= !!res
                        end
                    end

                else
                    signatures.each do |platform, p|
                        dopts = opts.dup
                        dopts[:platform] = platform

                        [p].flatten.compact.each do |signature|
                            res = find_signature( signature, response, dopts )
                            SIGNATURE_CACHE[:match][k] ||= !!res
                        end
                    end
                end

                return if !opts[:payload_platforms]

                # Find out if there are any signatures without associated payloads
                # and match them against every payload's response.
                signatures.select { |p, _|  !opts[:payload_platforms].include?( p ) }.
                    each do |platform, p|
                        dopts = opts.dup
                        dopts[:platform] = platform

                        [p].flatten.compact.each do |signature|
                            res = find_signature( signature, response, dopts )
                            SIGNATURE_CACHE[:match][k] ||= !!res
                        end
                    end
        end
    end

    def find_signature( signature, response, opts )
        if signature.respond_to?( :call )
            signature = signature.call( response )
        end

        return if !signature

        if signature.is_a? Regexp
            match_regexp_and_log( signature, response, opts )
        else
            find_substring_and_log( signature, response, opts )
        end
    end

    def find_substring_and_log( substring, response, opts )
        return if substring.to_s.empty?

        k = [substring, response.body]
        return if SIGNATURE_CACHE[:match][k] == false

        SIGNATURE_CACHE[:match][k] = includes = response.body.include?( substring )
        return if !includes || ignore?( response, opts )

        control_and_log(
            response:  response,
            platform:  opts[:platform],
            proof:     substring,
            signature: substring,
            vector:    response.request.performer
        )

        true
    end

    def match_regexp_and_log( regexp, response, opts )
        k = [regexp, response.body]
        return if SIGNATURE_CACHE[:match][k] == false

        match_data = response.body.match( regexp )
        return if !match_data

        match_data = match_data[0].to_s

        SIGNATURE_CACHE[:match][k] = !match_data.empty?

        return if match_data.empty? || ignore?( response, opts )

        control_and_log(
            response:  response,
            platform:  opts[:platform],
            proof:     match_data,
            signature: regexp,
            vector:    response.request.performer
        )

        true
    end

    def ignore?( response, opts )
        [opts[:ignore]].flatten.compact.each do |signature|
            return true if signature_match?( signature, response )
        end

        false
    end

    def signature_match?( signature, response )
        if signature.respond_to?( :call )
            signature = signature.call( response )
        end

        return if !signature

        if signature.is_a? Regexp
            response.body =~ signature
        else
            response.body.include?( signature )
        end
    end

    def control_and_log( issue )
        control = issue[:vector].dup

        if control.parameter_name_audit?
            inputs = control.inputs.dup
            value  = inputs.delete( control.seed )

            control.inputs = inputs.merge( Utilities.random_seed => value )
        else
            control.affected_input_value = Utilities.random_seed
        end

        control.submit do |response|
            # Something has gone wrong, timed-out request or closed connection.
            # If we can't verify the issue bail out...
            next if response.code == 0

            # If the signature matches the control response don't bother, it'll
            # be a coincidence causing a false positive.
            next if signature_match?( issue[:signature], response )

            # We can't have procs in there, we only log stuff that
            # can be serialized.
            issue[:vector].audit_options.delete :signatures

            @auditor.log( issue )
        end
    end

end
end
end
end
