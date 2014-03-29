=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'monitor'

module Arachni
class State

# Stores and provides access to all logged {Issue}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Issues
    include MonitorMixin

    EXTENSION = 'issue'

    def initialize
        super

        # Stores all issues with Issue#hash as the key as a way to deduplicate
        # and group variations.
        @collection = {}

        # Called when a new issue is logged.
        @on_new_blocks = []

        # Called whenever #<< is called.
        @on_new_pre_deduplication_blocks = []

        store
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
            sort_by { |i| Issue::Severity::ORDER.index i.severity.to_sym }
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
        @collection.include? issue.digest
    end

    # @note Will deduplicate and group issues as variations.
    #
    # @param    [Issue] issue   Issue to push to the collection.
    # @return   [Issues]    `self`
    def <<( issue )
        call_on_new_pre_deduplication_blocks( issue )

        # Only allow passive issues to have variations.
        return self if include?( issue ) && issue.active?

        synchronize do
            call_on_new_blocks( issue )

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
        all.sort_by { |i| Issue::Severity::ORDER.index i.severity.to_sym }
    end

    # @return   [Array<Integer>]    {Issue#hash}es.
    def hashes
        @collection.keys
    end

    # @param    [Block] block
    #   Block to be passed each new issue as it is logged by {#<<}.
    def on_new( &block )
        synchronize { @on_new_blocks << block }
        true
    end

    # @param    [Block] block
    #   Block to be passed each issue passed to {#<<}.
    def on_new_pre_deduplication( &block )
        synchronize { @on_new_pre_deduplication_blocks << block }
        true
    end

    def first
        @collection.first.last
    end

    def last
        @collection.last.last
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

    def store_or_update( directory )
        FileUtils.mkdir_p( directory )

        @collection.each do |digest, issue|
            File.open( "#{directory}/#{digest}.#{EXTENSION}", 'w' ) do |f|
                f.write Marshal.dump( issue )
            end
        end
    end

    def self.restore( directory )
        issues = new

        Dir["#{directory}/*.#{EXTENSION}"].each do |issue_file|
            issues << Marshal.load( IO.read( issue_file ) )
        end

        issues
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        @collection.hash
    end

    def clear
        @collection.clear
        @on_new_blocks.clear
        @on_new_pre_deduplication_blocks.clear
    end

    protected

    def collection
        @collection
    end

    private

    def call_on_new_blocks( issue )
        @on_new_blocks.each { |block| block.call issue }
    end

    def call_on_new_pre_deduplication_blocks( issue )
        @on_new_pre_deduplication_blocks.each { |block| block.call issue }
    end

end

end
end
