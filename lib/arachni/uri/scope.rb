=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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
    # @see #exclude_file_extension?
    def exclude?
        return true  if exclude_file_extension?
        return false if options.exclude_path_patterns.empty?

        s = @url.to_s
        !!options.exclude_path_patterns.find { |pattern| s =~ pattern }
    end

    # @return   [Bool]
    #   `true` if the resource extension is in {OptionGroups::Scope#@exclude_file_extensions},
    #   `false` otherwise.
    #
    # @see OptionGroups::Scope#@exclude_file_extensions
    def exclude_file_extension?
        options.exclude_file_extensions.any? &&
            options.exclude_file_extensions.include?(
                @url.resource_extension.to_s.downcase
            )
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

        options.include_subdomains ?
            Options.parsed_url.domain == @url.domain :
            Options.parsed_url.host == @url.host
    end

    # @return   [Bool]
    #   `true` if the protocol is within scope based on
    #   {OptionGroups::Scope#https_only}, `false` otherwise.
    #
    # @see OptionGroups::Scope#https_only
    def follow_protocol?
        return true if !Options.url

        check_scheme = @url.scheme

        return false if !check_scheme

        ref_scheme = Options.parsed_url.scheme

        return true if ref_scheme != 'https'
        return true if ref_scheme == check_scheme

        !options.https_only?
    end

    # @note Will decrease the redundancy counter.
    # @note Will first check with {#auto_redundant?}.
    #
    # @param    [Bool]   update_counters
    #   Whether or not to decrement the counters if `self` is redundant.
    #
    # @return   [Bool]
    #   `true` if the URL is redundant, `false` otherwise.
    #
    # @see OptionGroups::Scope#redundant_path_patterns
    def redundant?( update_counters = false )
        return true if auto_redundant?( update_counters )
        url_string = @url.to_s

        options.redundant_path_patterns.each do |regexp, count|
            next if !(url_string =~ regexp)
            return true if count == 0

            next if !update_counters
            options.redundant_path_patterns[regexp] -= 1
        end

        false
    end

    # @note Will decrease the redundancy counter.
    #
    # @param    [Bool]   update_counters
    #   Whether or not to increment the counters if `self` is redundant.
    #
    # @return   [Bool]
    #   `true` if the URL is redundant based on {OptionGroups::Scope#auto_redundant_paths},
    #   `false` otherwise.
    #
    # @see OptionGroups::Scope#auto_redundant_paths
    def auto_redundant?( update_counters = false )
        return false if !options.auto_redundant?
        return false if (params = @url.query_parameters).empty?

        h = "#{@url.without_query}#{params.keys.sort}".hash

        if options.auto_redundant_counter[h] >= options.auto_redundant_paths
            return true
        end

        if update_counters
            options.auto_redundant_counter[h] += 1
        end

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
