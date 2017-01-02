=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'rpc/serializer'

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Report
    include Utilities

    # @return    [String]
    #   {Arachni::VERSION}
    attr_accessor :version

    # @return    [String]
    #   Scan seed.
    attr_accessor :seed

    # @return    [Hash]
    #   {Options#to_h}
    attr_reader   :options

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_accessor :sitemap

    # @return    [Hash]
    #   Plugin results.
    attr_accessor :plugins

    # @return    [Time]
    #   The date and time when the scan started.
    attr_accessor :start_datetime

    # @return    [Time]
    #   The date and time when the scan finished.
    attr_accessor :finish_datetime

    def initialize( options = {} )
        options.each { |k, v| send( "#{k}=", v ) }

        @version     ||= Arachni::VERSION
        @seed        ||= Arachni::Utilities.random_seed
        @plugins     ||= {}
        @sitemap     ||= {}
        self.options ||= Options
        @issues      ||= {}

        @start_datetime  ||= Time.now
        @finish_datetime ||= Time.now
    end

    def url
        @options[:url]
    end

    # @note If no {#finish_datetime} has been provided, it will use `Time.now`.
    #
    # @return   [String]
    #   `{#start_datetime} - {#finish_datetime}` in `00:00:00`
    #   (`hours:minutes:seconds`) format.
    def delta_time
        seconds_to_hms( (@finish_datetime || Time.now) - @start_datetime )
    end

    # @param    [Options, Hash] options
    #   Scan {Options options}.
    #
    # @return   [Hash]
    def options=( options )
        @options = prepare_options( options )
    end

    # @param    [Array<Issue>]  issues
    #   Logged issues.
    #
    # @return    [Array<Issue>]
    #   Logged issues.
    def issues=( issues )
        @issues = {}
        issues.each do |issue|
            @issues[issue.digest] = issue
        end
        self.issues
    end

    # @param    [String]  check
    #   Check shortname.
    #
    # @return    [Array<Issue>]
    def issues_by_check( check )
        @issues.map do |_, issue|
            issue if issue.check[:shortname] == check.to_s
        end.compact
    end

    # @return    [Array<Issue>]
    #   Logged issues.
    def issues
        @issues.values
    end

    # @param    [Issue#digest]  digest
    #
    # @return    [Issue]
    def issue_by_digest( digest )
        @issues[digest]
    end

    # @param    [String]    report
    #   Location of the report.
    #
    # @return   [Hash]
    #   {#summary} associated with the given report.
    def self.read_summary( report )
        File.open( report ) do |f|
            f.seek -4, IO::SEEK_END
            summary_size = f.read( 4 ).unpack( 'N' ).first

            f.seek -summary_size-4, IO::SEEK_END
            RPC::Serializer.load( f.read( summary_size ) )
        end
    end

    # Loads and a {#save saved} {Report} object from file.
    #
    # @param    [String]    file
    #   File created by {#save}.
    #
    # @return    [Report]
    #   Loaded instance.
    def self.load( file )
        File.open( file, 'rb' ) do |f|
            f.seek -4, IO::SEEK_END
            summary_size = f.read( 4 ).unpack( 'N' ).first

            f.rewind
            from_rpc_data RPC::Serializer.load( f.read( f.size - summary_size ) )
        end
    end

    # @param    [String]    location
    #   Location for the {#to_afr dumped} report file.
    #
    # @return   [String]
    #   Absolute location of the report.
    def save( location = nil )
        default_filename = "#{URI(url).host} #{@finish_datetime.to_s.gsub( ':', '_' )}.afr"

        if !location
            location = default_filename
        elsif File.directory? location
            location += "/#{default_filename}"
        end

        IO.binwrite( location, to_afr )

        File.expand_path( location )
    end

    # @return   [String]
    #   Report serialized in the Arachni Framework Report format.
    def to_afr
        afr = RPC::Serializer.dump( self )

        # Append metadata to the end of the dump.
        metadata = RPC::Serializer.dump( summary )
        afr << [metadata, metadata.size].pack( 'a*N' )

        afr
    end

    # @return   [Hash]
    #   Hash representation of `self`.
    def to_h
        h = {
            version:         @version,
            seed:            @seed,
            options:         Arachni::Options.hash_to_rpc_data( @options ),
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
    #   Summary data of the report.
    def summary
        by_severity = Hash.new(0)
        @issues.each { |_, issue| by_severity[issue.severity.to_sym] += 1 }

        by_type = Hash.new(0)
        @issues.each { |_, issue| by_type[issue.name] += 1 }

        by_check = Hash.new(0)
        @issues.each { |_, issue| by_check[issue.check[:shortname]] += 1 }

        {
            version:         @version,
            seed:            @seed,
            url:             url,
            checks:          @options[:checks],
            plugins:         @options[:plugins].keys,
            issues: {
                total:       @issues.size,
                by_severity: by_severity,
                by_type:     by_type,
                by_check:    by_check
            },
            sitemap_size:    @sitemap.size,
            start_datetime:  @start_datetime.to_s,
            finish_datetime: @finish_datetime.to_s,
            delta_time:      delta_time
        }
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data = {}
        instance_variables.each do |ivar|
            data[ivar.to_s.gsub('@','')] = instance_variable_get( ivar )
        end

        data['options'] = Arachni::Options.hash_to_rpc_data( data['options'] )

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
            h[k] = v.my_symbolize_keys(false)
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

    # Prepares the hash to be stored in {Report#options}.
    #
    # The value of the 'options' key of the hash that initializes AuditObjects
    # needs some more processing before being saved in {Report#options}.
    #
    # @param    [Hash]  options
    # @return    [Hash]
    def prepare_options( options )
        Arachni::Options.rpc_data_to_hash( options.to_rpc_data_or_self )
    end

end
end
