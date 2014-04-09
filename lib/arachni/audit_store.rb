=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'zip'

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class AuditStore

    # @return    [String]    {Arachni::VERSION}
    attr_reader   :version

    # @return    [Hash]    {Options#to_h}
    attr_reader   :options

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_accessor :sitemap

    # @return    [Hash]  Plugin results.
    attr_accessor :plugins

    # @return    [Time]    The date and time when the scan started.
    attr_accessor :start_datetime

    # @return    [Time]    The date and time when the scan finished.
    attr_accessor :finish_datetime

    def initialize( options = {} )
        @version = Arachni::VERSION

        options.each { |k, v| send( "#{k}=", v ) }

        @plugins     ||= {}
        @sitemap     ||= {}
        self.options ||= Options
        @issues      ||= {}

        @start_datetime  ||= Time.now
        @finish_datetime ||= Time.now
    end

    # @note If no {#finish_datetime} has been provided, it will use `Time.now`.
    # @return   [String]
    #   `{#start_datetime} - {#finish_datetime}` in `00:00:00`
    #   (`hours:minutes:seconds`) format.
    def delta_time
        secs_to_hms( (@finish_datetime || Time.now) - @start_datetime )
    end

    # @param    [Options, Hash] options Scan {Options options}.
    # @return   [Hash]
    def options=( options )
        @options = prepare_options( options )
    end

    # @param    [Array<Issue>]  issues  Logged issues.
    # @return    [Array<Issue>]  Logged issues.
    def issues=( issues )
        @issues = {}
        issues.each do |issue|
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

    # Loads and a {#save saved} {AuditStore} object from file.
    #
    # @param    [String]    file
    #   File created by {#save}.
    #
    # @return    [AuditStore]
    #   Loaded instance.
    def self.load( file )
        Zip::File.open( file ) do |zip_file|
            Marshal.load zip_file.get_entry('report').get_input_stream.read
        end
    end

    # @param    [String]    location
    #   Location for the dumped report file.
    # @return   [String]
    #   Absolute location of the report.
    def save( location = nil )
        location ||= "#{URI(options[:url]).host} #{Time.now.to_s.gsub( ':', '.' )}.afr"

        Zip::File.open( location, Zip::File::CREATE ) do |zipfile|
            zipfile.get_output_stream( 'report' ) { |os| os.write Marshal.dump( self ) }
        end

        File.expand_path( location )
    end

    # @return    [Hash] Hash representation of `self`.
    def to_h
        hash = {
            version:         @version,
            options:         @options,
            sitemap:         @sitemap,
            start_datetime:  @start_datetime,
            finish_datetime: @finish_datetime,
            delta_time:      delta_time,
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
        options.to_hash.symbolize_keys( false )
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
