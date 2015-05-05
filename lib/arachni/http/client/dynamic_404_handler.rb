=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP
class Client

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Dynamic404Handler
    include UI::Output
    include Utilities

    # Maximum size of the cache that holds 404 signatures.
    CACHE_SIZE = 50

    # Maximum allowed difference ratio when comparing custom 404 signatures.
    # The fact that we refine the signatures allows us to set this threshold
    # really low and still maintain good accuracy.
    SIGNATURE_THRESHOLD = 0.1

    PRECISION = 2

    def initialize
        @static     = Support::LookUp::HashSet.new
        @signatures = Hash.new
    end

    # @param  [Response]  response
    #   Checks whether or not the provided response means 'not found'.
    # @param  [Block]   block
    #   To be passed `true` or `false` depending on the result of the analysis.
    def _404?( response, &block )
        url = response.url

        # Easy pickins, well-behaved static 404 handler and a URL that doesn't
        # need advanced analysis.
        if checked_and_static?( url )
            result = (response.code == 404)
            print_debug "#{__method__} [static]: #{block} #{url} #{result}"
            block.call( result )
            return
        end

        # We've hit the cache, hopefully some preliminary signature will
        # match the response body and we'll get to avoid the advanced analysis.
        if checked?( url )
            result = matches_preliminary_signatures?( url, response.body )

            # If we've got a positive result that's all we need to know, return
            # it immediately.
            if result
                print_debug "#{__method__} [cached]: #{block} #{url} #{result}"
                return block.call( result )
            end

            # If the result was negative only return it if there's no need for
            # advanced analysis for this resource.
            if !needs_advanced_analysis?( url )
                print_debug "#{__method__} [cached]: #{block} #{url} #{result}"
                return block.call( result )
            end
        end

        # No need to go over this process for each caller for the same handler,
        # group them together and they'll get notified when the analysis is
        # complete.
        data_for( url )[:waiting] << [url, response.code, response.body, block]
        if data_for( url )[:in_progress]
            print_debug "#{__method__} [waiting]: #{url} #{block}"
            return
        end
        data_for( url )[:in_progress] = true

        # If it's already checked then preliminary analysis has been performed
        # and since its results can be shared across different resource checks
        # don't waste time redoing it, we can jump straight into the advanced
        # analysis.
        if checked?( url ) && needs_advanced_analysis?( url )
            print_debug "#{__method__} [checking-advanced]: #{url} #{block}"
            process_advanced_analysis_callers_for( url )
            return
        end

        print_debug "#{__method__} [checking]: #{url} #{block}"

        # So... we've got nothing cached for the handler for this URL, let's
        # start from scratch.
        preliminary_analysis( url ) do
            process_callers_for( url )
        end

        nil
    end

    # @param    [String]    url
    #   URL to check.
    #
    # @return   [Bool]
    #   `true` if the `url` has been checked for the existence of a custom-404
    #   handler, `false` otherwise.
    def checked?( url )
        data_for( url )[:analyzed]
    end

    # @param    [String]    url
    #   URL to check.
    #
    # @return   [Bool]
    #   `true` if the `url` has been checked for the existence of a custom-404
    #   handler but none was identified, `false` otherwise.
    def checked_and_static?( url )
        @static.include?( url_for( url ) ) && !needs_advanced_analysis?( url )
    end

    # @param    [String]    url
    #   URL to check.
    #
    # @return   [Bool]
    #   `true` if the `url` needs to be checked for a {#_404?}, `false`
    #   otherwise.
    def needs_check?( url )
        !checked?( url ) || !checked_and_static?( url )
    end

    # @private
    def signatures
        @signatures
    end

    # @private
    def prune
        return if @signatures.size <= CACHE_SIZE

        @signatures.keys.each do |url|
            # If the path hasn't been analyzed yet skip it.
            next if !@signatures[url][:analyzed]

            # We've done enough...
            return if @signatures.size <= CACHE_SIZE

            @signatures.delete( url )
        end
    end

    private

    def preliminary_analysis( url, &block )
        generators = preliminary_probe_generators( url, PRECISION )

        real_404s          = 0
        corrupted          = false
        gathered_responses = 0
        expected_responses = generators.size * PRECISION

        generators.each.with_index do |generator, i|
            current_signature = (preliminary_signatures_for( url )[i] ||= {})

            PRECISION.times do
                Client.get( generator.call,
                            # This is important, helps us reduce waiting callers.
                            high_priority:   true,
                            performer:       self
                ) do |c_res|
                    next if corrupted

                    # Well, bad luck, bail out to avoid FPs.
                    if c_res.code == 0
                        print_debug "#{__method__} [corrupted]: #{url} #{block}"
                        corrupted = true
                        next clear_data_for( url )
                    end

                    gathered_responses += 1
                    if c_res.code == 404
                        real_404s += 1
                    end

                    if current_signature[:body]
                        current_signature[:rdiff] =
                            current_signature[:body].refine( c_res.body )

                        next if gathered_responses != expected_responses

                        if real_404s == expected_responses
                            @static << url_for( url )
                        end

                        block.call
                    else
                        current_signature[:body] = Support::Signature.new(
                            c_res.body, threshold: SIGNATURE_THRESHOLD
                        )
                    end
                end
            end
        end
    end

    def advanced_analysis( url, &block )
        generators = advanced_probe_generators( url, PRECISION )

        if generators.empty?
            block.call
            return
        end

        corrupted          = false
        gathered_responses = 0
        expected_responses = generators.size * PRECISION

        generators.each.with_index do |generator, i|
            current_signature = (advanced_signatures_for( url )[i] ||= {})

            PRECISION.times do
                Client.get( generator.call,
                            # This is important, helps us reduce waiting callers.
                            high_priority:   true,
                            performer:       self
                ) do |c_res|
                    next if corrupted

                    # Well, bad luck, bail out to avoid FPs.
                    if c_res.code == 0
                        print_debug "#{__method__} [corrupted]: #{url} #{block}"
                        corrupted = true
                        next clear_data_for( url )
                    end

                    gathered_responses += 1

                    if current_signature[:body]
                        current_signature[:rdiff] =
                            current_signature[:body].refine( c_res.body )

                        next if gathered_responses != expected_responses

                        block.call
                    else
                        current_signature[:body] = Support::Signature.new(
                            c_res.body, threshold: SIGNATURE_THRESHOLD
                        )
                    end
                end
            end
        end
    end

    def perform_advanced_analysis_if_necessary( url, body, &block )
        result = matches_preliminary_signatures?( url, body )
        print_debug "#{__method__} [checked]: #{block} #{url} #{result}"

        if result
            print_debug "#{__method__} [notify]: #{block} #{url} #{result}"
            checked( url )
            block.call( result )
            return
        end

        advanced_analysis url do
            checked( url )

            # If the signatures match after advanced analysis has been performed,
            # then this handler will always require advanced analysis for each
            # URL.
            result = matches_advanced_signatures?( url, body )
            print_debug "#{__method__} [notify]: #{block} #{url} #{result}"
            block.call result

            # More callers may have been added to the waiting queue during
            # the advanced analysis.
            process_callers_for( url )
        end
    end

    def process_callers_for( url )
        if checked_and_static?( url )
            checked( url )
            process_static_callers_for( url )
        else
            process_advanced_analysis_callers_for( url )
        end
    end

    def process_static_callers_for( url )
        while (waiting = data_for( url )[:waiting].pop)
            curl, code, _, callback = waiting
            result = (code == 404)
            print_debug "#{__method__} [notify]: #{callback} #{curl} #{result}"
            callback.call result
        end
    end

    def process_advanced_analysis_callers_for( url )
        while (waiting = data_for( url )[:waiting].pop)
            curl, _, body, callback = waiting
            perform_advanced_analysis_if_necessary( curl, body, &callback )
        end
    end

    def needs_advanced_analysis?( url )
        uri = uri_parse( url )
        resource_name = uri.resource_name.to_s.split('.').tap(&:pop).join('.')
        !!(!resource_name.empty? || uri.resource_extension)
    end

    def url_for( url )
        parsed = Arachni::URI( url )

        # If we're dealing with a file resource, then its parent directory will
        # be the applicable custom-404 handler...
        if parsed.resource_extension
            trv_back = Arachni::URI( parsed.up_to_path ).path

        # ...however, if we're dealing with a directory, the applicable handler
        # will be its parent directory.
        else
            trv_back = File.dirname( Arachni::URI( parsed.up_to_path ).path )
        end

        trv_back += '/' if trv_back[-1] != '/'

        parsed = parsed.dup
        parsed.path = trv_back
        parsed.to_s
    end

    # @return   [Array<Proc>]
    #   Generators for URLs which should elicit 404 responses for different types
    #   of scenarios.
    def preliminary_probe_generators( url, precision )
        uri        = uri_parse( url )
        up_to_path = uri.up_to_path

        trv_back = File.dirname( Arachni::URI( up_to_path ).path )
        trv_back += '/' if trv_back[-1] != '/'

        parsed = uri.dup
        parsed.path  = trv_back
        trv_back_url = parsed.to_s

        [
            # Get a random path with an extension.
            proc { up_to_path + random_string + '.' + random_string[0..precision] },

            # Get a random path without an extension.
            proc { up_to_path + random_string },

            # Get a random path without an extension with all caps.
            #
            # Yes, this is here due to a real use case...
            proc { up_to_path + random_string_alpha_capital },

            # Move up a dir and get a random file.
            proc { trv_back_url + random_string },

            proc { trv_back_url + random_string_alpha_capital },

            # Move up a dir and get a random file with an extension.
            proc { trv_back_url + random_string + '.' + random_string[0..precision] },

            # Get a random directory.
            proc { up_to_path + random_string + '/' }
        ]
    end

    # @return   [Array<Proc>]
    def advanced_probe_generators( url, precision )
        uri                = uri_parse( url )
        up_to_path         = uri.up_to_path
        resource_name      = uri.resource_name.to_s.split('.').tap(&:pop).join('.')
        resource_extension = uri.resource_extension

        probes = []

        if !resource_name.empty?
            # Get an existing resource with a random extension.
            probes << proc { up_to_path + resource_name + '.' + random_string[0..precision] }
        end

        if resource_extension
            # Get a random filename with an existing extension.
            probes << proc { up_to_path + random_string + '.' + resource_extension }
        end

        probes
    end

    def data_for( url )
        @signatures[url_for( url )] ||= signature_prototype
    end

    def clear_data_for( url )
        @signatures[url_for( url )] = signature_prototype
    end

    def signature_prototype
        {
            analyzed:    false,
            in_progress: false,
            waiting:     [],
            signatures:  {
                preliminary: [],
                advanced:    {}
            }
        }
    end

    def preliminary_signatures_for( url )
        data_for( url )[:signatures][:preliminary]
    end

    def advanced_signatures_for( url )
        data_for( url )[:signatures][:advanced][url] ||= []
    end

    def signatures_for( url )
        preliminary_signatures_for( url ) + advanced_signatures_for( url )
    end

    def checked( url )
        data = data_for( url )
        data[:analyzed]    = true
        data[:in_progress] = false
    end

    def matches_advanced_signatures?( url, body )
        # First try matching the signatures for the specific URL...
        advanced_signatures_for( url ).each do |signature|
            return true if signature[:rdiff].similar? signature[:body].refine( body )
        end

        false
    end

    def matches_preliminary_signatures?( url, body )
        # First try matching the signatures for the specific URL...
        preliminary_signatures_for( url ).each do |signature|
            return true if signature[:rdiff].similar? signature[:body].refine( body )
        end

        # ...then try the rest for good measure.
        url = url_for( url )
        @signatures.each do |u, data|
            next if u == url || !data[:analyzed]

            data[:signatures][:preliminary].each do |signature|
                return true if signature[:rdiff].similar? signature[:body].refine( body )
            end
        end

        false
    end

    def random_string
        Digest::SHA1.hexdigest( rand( 9999999 ).to_s )
    end

    def random_string_alpha_capital
        random_string.gsub( /\d/, '' ).upcase
    end

    def self.info
        { name: 'Dynamic404Handler' }
    end

end
end
end
end
