=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class URI

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope
    include UI::Output
    include Utilities

    personalize_output

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error
    end

    # @param    [Arachni::URI]  url
    def initialize( url )
        @url = url
    end

    # Checks if self exceeds a given directory `depth`.
    #
    # @param    [Integer]   depth
    #   Depth to check for.
    #
    # @return   [Bool]
    #   `true` if self is deeper than `depth`, `false` otherwise.
    def too_deep?( depth = Options.scope.directory_depth_limit )
        depth.to_i > 0 && (depth + 1) <= @url.path.to_s.count( '/' )
    end

    # Checks if self should be excluded based on the provided `patterns`.
    #
    # @param    [Array<Regexp,String>] patterns
    #
    # @return   [Bool]
    #   `true` if self matches a pattern, `false` otherwise.
    def exclude?( patterns = Options.scope.exclude_path_patterns )
        fail ArgumentError, 'Array<Regexp,String> expected, got nil instead' if !patterns

        !!ensure_patterns( patterns ).find { |pattern| @url.to_s =~ pattern }
    end

    # Checks if self should be included based on the provided `patterns`.
    #
    # @param    [Array<Regexp,String>] patterns
    #
    # @return   [Bool]
    #   `true` if self matches a pattern (or `patterns` are `nil` or empty),
    #   `false` otherwise.
    def include?( patterns = Options.scope.include_path_patterns )
        fail ArgumentError, 'Array<Regexp,String> expected, got nil instead' if !patterns

        rules = ensure_patterns( patterns )
        return true if rules.empty?

        !!rules.find { |pattern| @url.to_s =~ pattern }
    end

    # @param    [Arachni::URI, URI, Hash, String]    other
    #   Reference URL.
    # @param    [Bool]  include_subdomain Match subdomains too?
    #   If true will compare full hostnames, otherwise will discard subdomains.
    #
    # @return   [Bool]
    #   `true` if self is in the same domain as the `other` URL, false otherwise.
    def in_domain?( other = Options.url, include_subdomain = !Options.scope.include_subdomains )
        return true if !other

        other = URI( other ) if !other.is_a?( Arachni::URI )
        include_subdomain ? other.host == @url.host : other.domain == @url.domain
    rescue ArgumentError
        false
    end

    # Decides whether the given `url` has an acceptable protocol.
    #
    # @param    [String]    reference
    #   Reference URL.
    #
    # @return   [Bool]
    #
    # @see OptionGroups::Scope#https_only
    # @see OptionGroups::Scope#https_only?
    def follow_protocol?( reference = Options.url )
        return true if !reference

        check_scheme = @url.scheme.to_s

        return false if !%(http https).include?( check_scheme )

        parsed_ref = URI( reference )
        return false if !parsed_ref

        ref_scheme = parsed_ref.scheme

        return true if ref_scheme != 'https'
        return true if ref_scheme == check_scheme

        !Options.scope.https_only?
    end

    # Checks if `self` matches a redundancy filter and decreases its counter if
    # so.
    #
    # @return   [Bool]
    #   `true` if `self` is redundant, `false` otherwise.
    #
    # @see OptionGroups::Scope#redundant_path_patterns?
    def redundant?( &block )
        Options.scope.redundant?( @url.to_s, &block )
    end

    # @note Does **not** call {#redundant_path?}.
    #
    # @return   [Bool]
    #
    #   `true` if the URL is within the scan scope, `false` otherwise. The
    #   determination is based on:
    #
    #   * {#follow_protocol?}
    #   * {#in_domain?}
    #   * {#too_deep?}
    #   * {#include?}
    #   * {#exclude?}
    def in?
        !out?
    end

    # @note Does **not** call {#redundant?}.
    #
    # @return   [Bool]
    #
    #   `false` if the URL is within the scan scope, `true` otherwise. The
    #   determination is based on:
    #
    #   * {#follow_protocol?}
    #   * {#in_domain?}
    #   * {#too_deep?}
    #   * {#include?}
    #   * {#exclude?}
    def out?
        return true if !follow_protocol?
        return true if !in_domain?
        return true if too_deep?
        return true if !include?
        return true if exclude?

        false
    end

    private

    def ensure_patterns( arr )
        if arr.is_a?( Array )
            arr
        else
            [arr].flatten
        end.compact.map { |p| p.is_a?( Regexp ) ? p : Regexp.new( p.to_s ) }
    end

end

end
end
