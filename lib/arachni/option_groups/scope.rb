=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::OptionGroups

# Scan scope options, maintains rules used to decide which resources should be
# considered for crawling/auditing/etc. during the scan.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < Arachni::OptionGroup

    # @note `nil` is infinite -- default is `nil`.
    # @return    [Integer]  How deep to go into the site's directory tree.
    #
    # @see Utilities#skip_resource?
    # @see Trainer#push
    # @see Framework#push_to_page_queue
    # @see Framework#push_to_url_queue
    # @see Framework#audit_page
    # @see Browser
    attr_accessor :directory_depth_limit

    # @note `nil` is infinite -- default is `10`.
    # @return    [Integer]  How deep to go into each page's DOM tree.
    #
    # @see Browser
    # @see Framework#push_to_page_queue
    # @see Framework#push_to_url_queue
    # @see Framework#audit_page
    attr_accessor :dom_depth_limit

    # @note `nil` is infinite -- default is `nil`.
    # @return    [Integer]  How many pages to consider (crawl/audit)?
    #
    # @see Framework#push_to_page_queue
    # @see Framework#push_to_url_queue
    # @see Framework#audit_page
    # @see Trainer#push
    attr_accessor :page_limit

    # @return   [Array<String>] Paths to use instead of crawling.
    #
    # @see Framework#push_to_url_queue
    # @see Framework#audit
    attr_accessor :restrict_paths

    # @return   [String]    Path to file containing {#restrict_paths}.
    attr_accessor :restrict_paths_filepath

    # @return   [Array<String>] Paths to use in addition to crawling.
    #
    # @see Framework#push_to_page_queue
    # @see Framework#push_to_url_queue
    attr_accessor :extend_paths

    # @return   [String] Path to file containing {#extend_paths}.
    attr_accessor :extend_paths_filepath

    # @return    [Hash{Regexp => Integer}]
    #   Filters for redundant paths in the form of `{ pattern => counter }`.
    #   Once the `pattern` has matched a path `counter` amount of times, the
    #   resource will be ignored from then on.
    #
    #   Useful when scanning pages that dynamically generate a large number of
    #   pages like galleries and calendars.
    #
    # @see #redundant?
    # @see Utilities#redundant_path?
    # @see Trainer#push
    # @see Browser
    attr_accessor :redundant_path_patterns

    # @return   [Bool]
    #   Sets a limit to how many paths with identical query parameter names to
    #   process. Helps avoid processing redundant/identical resources like
    #   entries in calendars and catalogs.
    #
    # @see #auto_redundant_path?
    # @see Trainer#push
    # @see Browser
    attr_accessor :auto_redundant_paths

    # @return    [Array<Regexp>]
    #   Path inclusion patterns, only resources that match any of the specified
    #   patterns will be considered.
    #
    # @see Utilities#include_path?
    # @see Trainer#push
    # @see Browser
    attr_accessor :include_path_patterns

    # @return    [Array<Regexp>]
    #   Path exclusion patterns, resources that match any of the specified
    #   patterns will not be considered.
    #
    # @see Utilities#exclude_path?
    # @see Trainer#push
    # @see Browser
    attr_accessor :exclude_path_patterns

    # @return    [Array<Regexp>]
    #   Page bodies matching any of these patterns will be are ignored.
    #
    # @see #exclude_page?
    # @see Utilities#skip_resource?
    # @see Browser
    attr_accessor :exclude_page_patterns

    # @note Default if `false`.
    # @return    [Bool]
    #   Take into consideration URLs pointing to different subdomains from the
    #   {Options#url seed URL}.
    attr_accessor :include_subdomains

    # @return   [Bool]
    #   If an HTTPS {Options#url} has been provided, **do not** downgrade to to
    #   a insecure link.
    attr_accessor :https_only
    alias :https_only? :https_only
    
    set_defaults(
        redundant_path_patterns: {},
        dom_depth_limit:         10,
        exclude_path_patterns:   [],
        exclude_page_patterns:   [],
        include_path_patterns:   [],
        restrict_paths:          [],
        extend_paths:            []
    )

    # These options need to contain Array<String>.
    [ :restrict_paths, :extend_paths ].each do |m|
        define_method( "#{m}=".to_sym ) do |arg|
            arg = [arg].flatten.compact.map { |s| s.to_s }
            instance_variable_set( "@#{m}".to_sym, arg )
        end
    end

    # these options need to contain Array<Regexp>
    [ :exclude_page_patterns, :include_path_patterns, :exclude_path_patterns ].each do |m|
        define_method( "#{m}=".to_sym ) do |arg|
            arg = [arg].flatten.compact.
                map { |s| s.is_a?( Regexp ) ? s : Regexp.new( s.to_s ) }
            instance_variable_set( "@#{m}".to_sym, arg )
        end
    end

    # Checks is the provided URL matches a redundant filter and decreases its
    # counter if so.
    #
    # If a filter's counter has reached 0 the method returns true.
    #
    # @param    [String]    url
    # @param    [Block]     block
    #   To be called for each match and be passed the count, regexp and url.
    #
    # @return   [Bool]  true if the url is redundant, false otherwise
    #
    # @see #redundant
    def redundant?( url, &block )
        redundant_path_patterns.each do |regexp, count|
            next if !(url =~ regexp)
            return true if count == 0

            block.call( count, regexp, url ) if block_given?

            redundant_path_patterns[regexp] -= 1
        end
        false
    end

    def auto_redundant_path?( url, &block )
        return false if !auto_redundant?
        @auto_redundant_h ||= Hash.new( 0 )

        h = "#{url.split( '?' ).first}#{Arachni::Link.parse_query_vars( url ).keys.sort}".hash

        if @auto_redundant_h[h] >= auto_redundant_paths
            block.call( @auto_redundant_h[h] ) if block_given?
            return true
        end

        @auto_redundant_h[h] += 1
        false
    end

    def dom_depth_limit_reached?( page )
        dom_depth_limit && page.dom.depth > dom_depth_limit
    end

    # Checks if the given string matches one of the configured
    # {#exclude_page_patterns} patterns.
    #
    # @param    [String]    body
    # @return   [Bool]
    #   `true` if `body` matches an {#exclude_page_patterns} pattern,
    #   `false` otherwise.
    #
    # @see #exclude_page_patterns
    def exclude_page?( body )
        exclude_page_patterns.each { |i| return true if body.to_s =~ i }
        false
    end

    def auto_redundant?
        !!@auto_redundant_paths
    end

    def do_not_crawl
        self.page_limit = 0
    end

    def crawl
        self.page_limit = nil
    end

    def crawl?
        !page_limit || page_limit != 0
    end

    def page_limit_reached?( count )
        page_limit && page_limit.to_i > 0 && count >= page_limit
    end

    # Sets the redundancy filters.
    #
    # Filter example:
    #    {
    #        # regexp           counter
    #        /calendar\.php/ => 5
    #        'gallery\.php' => '3'
    #    }
    #
    # @param     [Hash]  filters
    def redundant_path_patterns=( filters )
        if filters.nil?
            return @redundant_path_patterns =
                defaults[:redundant_path_patterns].dup
        end

        @redundant_path_patterns =
             filters.inject({}) do |h, (regexp, counter)|
                 regexp = regexp.is_a?( Regexp ) ? regexp : Regexp.new( regexp.to_s )
                 h.merge!( regexp => Integer( counter ) )
                 h
             end
    end

end
end
