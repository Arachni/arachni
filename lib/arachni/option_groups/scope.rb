=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Scan scope options, maintains rules used to decide which resources should be
# considered for crawling/auditing/etc. during the scan.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope < Arachni::OptionGroup

    # @note `nil` is infinite -- default is `nil`.
    #
    # @return    [Integer]
    #   How deep to go into the site's directory tree.
    #
    # @see URI::Scope#too_deep?
    attr_accessor :directory_depth_limit

    # @note `nil` is infinite -- default is `10`.
    #
    # @return    [Integer]
    #   How deep to go into each page's DOM tree.
    #
    # @see Page::Scope#dom_depth_limit_reached?
    attr_accessor :dom_depth_limit

    # @note `nil` is infinite -- default is `nil`.
    #
    # @return    [Integer]
    #   How many DOM events to trigger for each snapshot.
    #
    # @see Browser#trigger_events
    attr_accessor :dom_event_limit

    # @note `nil` is infinite -- default is `nil`.
    #
    # @return    [Integer]
    #   How many pages to consider (crawl/audit)?
    #
    # @see Framework#push_to_page_queue
    # @see Framework#push_to_url_queue
    # @see Framework#audit_page
    # @see Trainer#push
    attr_accessor :page_limit

    # @return   [Array<String>]
    #   Paths to use instead of crawling.
    #
    # @see Framework#push_to_url_queue
    attr_accessor :restrict_paths

    # @return   [Array<String>]
    #   Paths to use in addition to crawling.
    #
    # @see Framework#push_to_page_queue
    # @see Framework#push_to_url_queue
    attr_accessor :extend_paths

    # @return    [Hash{Regexp => Integer}]
    #   Filters for redundant paths in the form of `{ pattern => counter }`.
    #   Once the `pattern` has matched a path `counter` amount of times, the
    #   resource will be ignored from then on.
    #
    #   Useful when scanning pages that dynamically generate a large number of
    #   pages like galleries and calendars.
    #
    # @see URI::Scope#redundant?
    attr_accessor :redundant_path_patterns

    # @return   [Bool]
    #   Sets a limit to how many paths with identical query parameter names to
    #   process. Helps avoid processing redundant/identical resources like
    #   entries in calendars and catalogs.
    #
    # @see URI::Scope#redundant?
    # @see URI::Scope#auto_redundant?
    attr_accessor :auto_redundant_paths

    # @return    [Array<Regexp>]
    #   Path inclusion patterns, only resources that match any of the specified
    #   patterns will be considered.
    #
    # @see URI::Scope#include?
    attr_accessor :include_path_patterns

    # @return    [Array<String>]
    #   Extension exclusion patterns, resources whose extension is in the list
    #   will not be considered.
    #
    # @see URI::Scope#exclude_file_extension?
    attr_accessor :exclude_file_extensions

    # @return    [Array<Regexp>]
    #   Path exclusion patterns, resources that match any of the specified
    #   patterns will not be considered.
    #
    # @see URI::Scope#exclude?
    attr_accessor :exclude_path_patterns

    # @return    [Array<Regexp>]
    #   {Page}/{HTTP::Response} bodies matching any of these patterns will be are ignored.
    #
    # @see HTTP::Response::Scope#exclude_content?
    attr_accessor :exclude_content_patterns

    # @note Default is `false`.
    #
    # @return   [Bool]
    #   Exclude pages with binary content from the audit. Mainly used to avoid
    #   having grep checks confused by random binary content.
    #
    # @see HTTP::Response::Scope#exclude_as_binary?
    attr_accessor :exclude_binaries
    alias :exclude_binaries? :exclude_binaries

    # @note Default if `false`.
    #
    # @return    [Bool]
    #   Take into consideration URLs pointing to different subdomains from the
    #   {Options#url seed URL}.
    #
    # @see URI::Scope#in_domain?
    attr_accessor :include_subdomains

    # @return   [Bool]
    #   If an HTTPS {Options#url} has been provided, **do not** downgrade to to
    #   a insecure link.
    #
    # @see URI::Scope#follow_protocol?
    attr_accessor :https_only
    alias :https_only? :https_only

    # @return   [Hash<Regexp => String>]
    #   Regular expression and substitution pairs, used to rewrite
    #   {Element::Capabilities::Submittable#action}.
    #
    # @see URI.rewrite
    # @see URI#rewrite
    attr_accessor :url_rewrites

    set_defaults(
        redundant_path_patterns:  {},
        dom_depth_limit:          5,
        exclude_file_extensions:  Set.new,
        exclude_path_patterns:    [],
        exclude_content_patterns: [],
        include_path_patterns:    [],
        restrict_paths:           [],
        extend_paths:             [],
        url_rewrites:             {}
    )

    def url_rewrites=( rules )
        return @url_rewrites = defaults[:url_rewrites].dup if !rules

        @url_rewrites = rules.inject({}) do |h, (regexp, value)|
            regexp = regexp.is_a?( Regexp ) ?
                regexp :
                Regexp.new( regexp.to_s, Regexp::IGNORECASE )
            h.merge!( regexp => value )
            h
        end
    end

    def exclude_file_extensions=( ext )
        return @exclude_file_extensions =
            defaults[:exclude_file_extensions].dup if !ext

        if ext.is_a? Set
            @exclude_file_extensions = ext
        else
            @exclude_file_extensions = Set.new(
                [ext].flatten.compact.map { |s| s.to_s.downcase }
            )
        end
    end

    # These options need to contain Array<String>.
    [ :restrict_paths, :extend_paths ].each do |m|
        define_method( "#{m}=".to_sym ) do |arg|
            arg = [arg].flatten.compact.map { |s| s.to_s }
            instance_variable_set( "@#{m}".to_sym, arg )
        end
    end

    # These options need to contain Array<Regexp>.
    [ :exclude_content_patterns, :include_path_patterns, :exclude_path_patterns ].each do |m|
        define_method( "#{m}=".to_sym ) do |arg|
            arg = [arg].flatten.compact.
                map { |s| s.is_a?( Regexp ) ?
                s :
                Regexp.new( s.to_s, Regexp::IGNORECASE ) }
            instance_variable_set( "@#{m}".to_sym, arg )
        end
    end

    def auto_redundant?
        !!@auto_redundant_paths
    end

    def auto_redundant_counter
        @auto_redundant_counter ||= Hash.new( 0 )
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

    def dom_event_limit_reached?( count )
        dom_event_limit && count >= dom_event_limit
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
                 regexp = regexp.is_a?( Regexp ) ?
                     regexp :
                     Regexp.new( regexp.to_s, Regexp::IGNORECASE )
                 h.merge!( regexp => Integer( counter ) )
                 h
             end
    end

    def to_rpc_data
        d = super

        d['exclude_file_extensions'] = d['exclude_file_extensions'].to_a

        %w(redundant_path_patterns url_rewrites).each do |k|
            d[k] = d[k].inject({}) { |h, (k2, v)| h.merge k2.source => v }
        end

        %w(exclude_path_patterns exclude_content_patterns include_path_patterns).each do |k|
            d[k] = d[k].map(&:source)
        end

        d
    end

end
end
