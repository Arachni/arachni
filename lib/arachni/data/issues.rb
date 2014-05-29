=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'monitor'

module Arachni
class Data

# Stores and provides access to all logged {Issue}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Issues
    include Support::Mixins::Observable

    # @!method on_new_pre_deduplication( &block )
    #   @param    [Block] block
    #       Block to be passed each issue passed to {#<<}.
    advertise :on_new_pre_deduplication
    advertise :on_new

    # @return   [Hash{Integer=>Issue}]  Issues by their {Issue#digest}.
    attr_reader :collection

    # @return   [Set<Integer>]    {Issue#digest}s.
    attr_reader :digests

    def initialize
        super

        # Stores all issues with Issue#digest as the key as a way to deduplicate
        # and group variations.
        @collection = {}

        # We also use this Set for deduplication in case #do_not_store has been
        # called.
        @digests = Set.new

        store
    end

    def statistics
        by_severity = Hash.new(0)
        each { |issue| by_severity[issue.severity.to_sym] += 1 }

        by_type = Hash.new(0)
        each { |issue| by_type[issue.name] += 1 }

        by_check = Hash.new(0)
        each { |issue| by_check[issue.check[:shortname]] += 1 }

        {
            total:       size,
            by_severity: by_severity,
            by_type:     by_type,
            by_check:    by_check
        }
    end

    # @note Defaults to `true`.
    # @return   [Bool]
    #   `true` if {#<<} is configured to store issues, `false` otherwise.
    #
    # @see #<<
    def store?
        @store
    end

    # Enables issue storage via {#<<}.
    #
    # @see #store?
    # @see #<<
    def store
        @store = true
        self
    end

    # Disables issue storage via {#<<}.
    #
    # @see #store?
    # @see #<<
    def do_not_store
        @store = false
        self
    end

    # @return   [Array<Issue>]
    #   All logged issues grouped as variations.
    def all
        @collection.values
    end

    # @return   [Array<Issue>]
    #   First variation of all issues (as solo issues) sorted by severity.
    def summary
        all.map { |issue| issue.variations.first.to_solo issue }.flatten.
            sort_by(&:severity).reverse
    end

    # @return   [Array<Issue>]
    #   All logged issues as solo objects, without variations.
    def flatten
        all.map { |issue| issue.variations.map { |v| v.to_solo issue } }.flatten
    end

    def each( &block )
        all.each( &block )
    end

    def map( &block )
        all.map( &block )
    end

    # @return   [Bool]
    #   `true` if `issue` is
    def include?( issue )
        @digests.include? issue.digest
    end

    # @note Will deduplicate and group issues as variations.
    #
    # @param    [Issue] issue   Issue to push to the collection.
    # @return   [Issues]    `self`
    def <<( issue )
        notify_on_new_pre_deduplication( issue )

        # Only allow passive issues to have variations.
        return self if include?( issue ) && issue.active?

        @digests << issue.digest

        synchronize do
            notify_on_new( issue )

            if store?
                id = issue.digest
                @collection[id] ||= issue.with_variations
                @collection[id].variations << issue.as_variation
            end
        end

        self
    end

    # @param    [Integer]   digest    {Issue#digest}
    # @return   [Issue]
    def []( digest )
        @collection[digest]
    end

    # @return   [Array<Issue>]  Sorted array of {Issue}s.
    def sort
        all.sort_by(&:severity).reverse
    end

    def first
        @collection.values.first
    end

    def last
        @collection.values.last
    end

    def any?
        @collection.any?
    end

    def empty?
        !any?
    end

    def size
        @collection.size
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        @collection.each do |digest, issue|
            IO.binwrite( "#{directory}/issue_#{digest}", Marshal.dump( issue ) )
        end

        IO.binwrite( "#{directory}/digests", Marshal.dump( digests ) )
    end

    def self.load( directory )
        issues = new

        Dir["#{directory}/issue_*"].each do |issue_file|
            issue = Marshal.load( IO.binread( issue_file ) )
            issues.collection[issue.digest] = issue
        end

        issues.digests.merge Marshal.load( IO.binread( "#{directory}/digests" ) )

        issues
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        @digests.hash
    end

    def clear
        @digests.clear
        @collection.clear
        clear_observers
    end

end

end
end
