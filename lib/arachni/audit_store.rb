=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class AuditStore

    # @return    [String]    {Arachni::VERSION}
    attr_reader   :version

    # @return    [Hash]    {Options#to_h}
    attr_reader   :options

    # @return    [Array]   All the urls crawled and audited.
    attr_accessor :sitemap

    # @return    [Hash]  Plugin results.
    attr_accessor :plugins

    # @return    [String]    The date and time when the scan started.
    attr_reader   :start_datetime

    # @return    [String]    The date and time when the scan finished.
    attr_reader   :finish_datetime

    # @return    [String]    How long the scan took.
    attr_reader   :delta_time

    def initialize( options = {} )
        @version = Arachni::VERSION

        options.each { |k, v| send( "#{k}=", v ) }

        @plugins     ||= {}
        @sitemap     ||= []
        self.options ||= Options
        @issues      ||= {}
    end

    # @param    [Options, Hash] options Scan {Options options}.
    # @return   [Hash]
    def options=( options )
        @options = prepare_options( options )

        @start_datetime  =  @options['start_datetime'] ?
            @options['start_datetime'].asctime : Time.now.asctime

        @finish_datetime = @options['finish_datetime'] ?
            @options['finish_datetime'].asctime : Time.now.asctime

        @delta_time = secs_to_hms( @options['delta_time'] )

        @options
    end

    # @param    [Array<Issue>]  issues  Logged issues.
    # @return   [Array<Issue>]
    #   Logged issues sorted and grouped into variations.
    def issues=( issues )
        @issues = {}
        Issue.sort( prepare_variations( issues ) ).each do |issue|
            @issues[issue.digest] = issue
        end
        self.issues
    end

    # @return    [Array<Issue>]  Logged issues.
    def issues
        @issues.values
    end

    # @param    [Issue#digest]  digest
    # @return    [Issue]
    def issue_by_digest( digest )
        @issues[digest]
    end

    # Loads and returns an AuditStore object from file
    #
    # @param    [String]    file    the file to load
    #
    # @return    [AuditStore]
    def self.load( file )
         begin
             r = YAML.load( IO.read( file ) )
             r.version
             r
         rescue Exception => e
             Marshal.load( File.binread( file ) )
         end
    end

    # Saves 'self' to file
    #
    # @param    [String]    file
    def save( file )
        begin
            File.open( file, 'w' ) { |f| f.write( YAML.dump( self ) ) }
        rescue
            File.open( file, 'wb' ) { |f| f.write( Marshal.dump( self ) ) }
        end
    end

    # @return    [Hash] Hash representation of `self`.
    def to_h
        hash = {
            version:         @version,
            options:         @options,
            sitemap:         @sitemap,
            start_datetime:  @start_datetime,
            finish_datetime: @finish_datetime,
            delta_time:      @delta_time,
            issues:          issues.map(&:to_h),
            plugins:         @plugins.deep_clone
        }

        hash[:plugins].each do |plugin, data|
            next if !data[:options]
            hash[:plugins][plugin][:options] = data[:options].map(&:to_h)
        end

        hash.recode
    end
    alias :to_hash :to_h

    def ==( other )
        to_h == other.to_h
    end

    def hash
        to_hash.hash
    end

    private

    # Prepares the hash to be stored in {AuditStore#options}
    #
    # The value of the 'options' key of the hash that initializes AuditObjects
    # needs some more processing before being saved in {AuditStore#options}.
    #
    # @param    [Hash]  options
    # @return    [Hash]
    def prepare_options( options )
        new_options = {}

        options.to_hash.each do |key, val|
            case key
                when 'redundant'
                    new_options[key.to_s] = {}
                    val.each do |regexp, counter|
                        new_options[key.to_s].merge!( regexp.to_s => counter )
                    end

                when 'exclude', 'include'
                    new_options[key.to_s] = []
                    val.each { |regexp| new_options[key.to_s] << regexp.to_s }

                when 'cookies'
                    next if !val
                    new_options[key.to_s] =
                        val.inject( {} ){ |h, c| h.merge!( c.simple ) }

                else
                    new_options[key.to_s] = val
            end
        end

        new_options
    end

    # @param    [Array<Issue>]    issues
    # @return    [Array<Issue>]
    #   New array of Issues with populated {Issue#variations}.
    #
    # @see Issue#variations
    def prepare_variations( issues )
        new_issues = {}
        issues.each do |issue|
            id = issue.hash
            new_issues[id] ||= issue.with_variations
            new_issues[id].variations << issue.as_variation
        end

        new_issues.values
    end

    # @param    [String, Float, Integer]    seconds
    # @return    [String]
    #   Time in `00:00:00` (`hours:minutes:seconds`) format.
    def secs_to_hms( seconds )
        seconds = seconds.to_i
        [seconds / 3600, seconds / 60 % 60, seconds % 60].
            map { |t| t.to_s.rjust( 2, '0' ) }.join( ':' )
    end

end
end
