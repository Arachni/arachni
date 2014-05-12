=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'zip'

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class AuditStore
    include Utilities

    # @return    [String]    {Arachni::VERSION}
    attr_accessor :version

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
        options.each { |k, v| send( "#{k}=", v ) }

        @version     ||= Arachni::VERSION
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
        default_filename = "#{URI(options[:url]).host} #{@finish_datetime.to_s.gsub( ':', '.' )}.afr"

        if !location
            location = default_filename
        elsif File.directory? location
            location += "/#{default_filename}"
        end

        Zip::File.open( location, Zip::File::CREATE ) do |zipfile|
            zipfile.get_output_stream( 'report' ) { |os| os.write Marshal.dump( self ) }
        end

        File.expand_path( location )
    end

    # @return   [Hash]  Hash representation of `self`.
    def to_h
        h = {
            version:         @version,
            options:         @options,
            sitemap:         @sitemap,
            start_datetime:  @start_datetime.to_s,
            finish_datetime: @finish_datetime.to_s,
            delta_time:      delta_time,
            issues:          issues.map(&:to_h),
            plugins:         @plugins.dup
        }

        h[:plugins].each do |plugin, data|
            next if !data[:options]
            h[:plugins][plugin] = h[:plugins][plugin].dup
            h[:plugins][plugin][:options] = h[:plugins][plugin][:options].dup
            h[:plugins][plugin][:options] = data[:options].map(&:to_h)
        end

        h#.recode
    end
    alias :to_hash :to_h

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data = {}
        instance_variables.each do |ivar|
            data[ivar.to_s.gsub('@','')] = instance_variable_get( ivar )
        end

        data['plugins'].each do |plugin, d|
            next if !d[:options]

            data['plugins'] = data['plugins'].dup
            data['plugins'][plugin] = data['plugins'][plugin].dup
            data['plugins'][plugin][:options] = data['plugins'][plugin][:options].dup
            data['plugins'][plugin][:options] = d[:options].map(&:to_rpc_data)
        end

        data['issues']          = data['issues'].values.map(&:to_rpc_data)
        data['start_datetime']  = data['start_datetime'].to_s
        data['finish_datetime'] = data['finish_datetime'].to_s
        data
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [DOM]
    def self.from_rpc_data( data )
        data['start_datetime']  = Time.parse( data['start_datetime'] )
        data['finish_datetime'] = Time.parse( data['finish_datetime'] )

        data['issues'] = data['issues'].map { |i| Arachni::Issue.from_rpc_data( i ) }

        data['plugins'] = data['plugins'].inject({}) do |h, (k, v)|
            k    = k.to_sym
            h[k] = v.symbolize_keys(false)
            next h if !h[k][:options]

            h[k][:options] = v['options'].map do |option|
                klass = option['class'].split( '::' ).last.to_sym
                Component::Options.const_get( klass ).from_rpc_data( option )
            end
            h
        end
        new data
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        h = to_hash
        [:start_datetime, :finish_datetime, :delta_datetime].each do |k|
            h.delete k
        end
        h.hash
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
        options.to_hash.symbolize_keys
    end

end
end
