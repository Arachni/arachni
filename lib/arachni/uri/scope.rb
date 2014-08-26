=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class URI

# Determines the {Scope scope} status of {Arachni::URI}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope < Arachni::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Scope::Error
    end

    # @param    [Arachni::URI]  url
    def initialize( url )
        @url = url
    end

    # @return   [Bool]
    #   `true` if the URL is deeper than `depth`, `false` otherwise.
    #
    # @see OptionGroups::Scope#directory_depth_limit
    def too_deep?
        depth = options.directory_depth_limit
        depth.to_i > 0 && (depth + 1) <= @url.path.to_s.count( '/' )
    end

    # @return   [Bool]
    #   `true` if the URL matches any {OptionGroups::Scope#exclude_path_patterns},
    #   `false` otherwise.
    #
    # @see OptionGroups::Scope#exclude_path_patterns
    def exclude?
        !!options.exclude_path_patterns.find { |pattern| @url.to_s =~ pattern }
    end

    # @return   [Bool]
    #   `true` if the URL matches any {OptionGroups::Scope#include_path_patterns},
    #   `false` otherwise.
    #
    # @see OptionGroups::Scope#include_path_patterns
    def include?
        rules = options.include_path_patterns
        return true if rules.empty?

        !!rules.find { |pattern| @url.to_s =~ pattern }
    end

    # @return   [Bool]
    #   `true` if self is in the same domain as {Options#url}, `false` otherwise.
    #
    # @see OptionGroups::Scope#include_subdomains
    def in_domain?
        return true if !Options.url

        reference = Arachni::URI( Options.url )

        options.include_subdomains ?
            reference.domain == @url.domain : reference.host == @url.host
    end

    # @return   [Bool]
    #   `true` if the protocol is within scope based on
    #   {OptionGroups::Scope#https_only}, `false` otherwise.
    #
    # @see OptionGroups::Scope#https_only
    def follow_protocol?
        return true if !Options.url

        check_scheme = @url.scheme.to_s

        return false if !%(http https).include?( check_scheme )

        parsed_ref = Arachni::URI( Options.url )
        return false if !parsed_ref

        ref_scheme = parsed_ref.scheme

        return true if ref_scheme != 'https'
        return true if ref_scheme == check_scheme

        !options.https_only?
    end

    # @note Will decrease the redundancy counter.
    # @note Will first check with {#auto_redundant?}.
    #
    # @return   [Bool]
    #   `true` if the URL is redundant, `false` otherwise.
    #
    # @see OptionGroups::Scope#redundant_path_patterns
    def redundant?
        return true if auto_redundant?
        url_string = @url.to_s

        options.redundant_path_patterns.each do |regexp, count|
            next if !(url_string =~ regexp)
            return true if count == 0

            options.redundant_path_patterns[regexp] -= 1
        end

        false
    end

    # @note Will decrease the redundancy counter.
    #
    # @return   [Bool]
    #   `true` if the URL is redundant based on {OptionGroups::Scope#auto_redundant_paths},
    #   `false` otherwise.
    #
    # @see OptionGroups::Scope#auto_redundant_paths
    def auto_redundant?
        return false if !options.auto_redundant?

        h = "#{@url.without_query}#{@url.query_parameters.keys.sort}".hash

        if options.auto_redundant_counter[h] >= options.auto_redundant_paths
            return true
        end

        options.auto_redundant_counter[h] += 1
        false
    end

    # @return   [Bool]
    #   `true` if the URL is not {#out?} of the scan {OptionGroups::Scope scope},
    #   `false` otherwise.
    def in?
        !out?
    end

    # @note Does **not** call {#redundant?}.
    #
    # @return   [Bool]
    #   `true` if the URL out of the scan {OptionGroups::Scope scope}, `false`
    #   otherwise. The determination is based on:
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
    
end

end
end
