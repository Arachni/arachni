=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides a {Arachni::Report::Manager} and related helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Report

    # @return   [Arachni::Reporter::Manager]
    attr_reader :reporters

    def initialize
        super

        # Deep clone the redundancy rules to preserve their original counters
        # for the reports.
        @original_redundant_path_patterns =
            options.scope.redundant_path_patterns.deep_clone

        @reporters = Arachni::Reporter::Manager.new
    end

    # @return    [Report]
    #   Scan results.
    def report
        opts = options.to_hash.deep_clone

        # restore the original redundancy rules and their counters
        opts[:scope][:redundant_path_patterns] = @original_redundant_path_patterns

        Arachni::Report.new(
            options:         options,
            sitemap:         sitemap,
            issues:          Arachni::Data.issues.sort,
            plugins:         @plugins.results,
            start_datetime:  @start_datetime,
            finish_datetime: @finish_datetime
        )
    end

    # Runs a reporter component and returns the contents of the generated report.
    #
    # Only accepts reporters which support an `outfile` option.
    #
    # @param    [String]    name
    #   Name of the reporter component to run, as presented by {#list_reporters}'s
    #   `:shortname` key.
    # @param    [Report]    external_report
    #   Report to use -- defaults to the local one.
    #
    # @return   [String]
    #   Scan report.
    #
    # @raise    [Component::Error::NotFound]
    #   If the given reporter name doesn't correspond to a valid reporter component.
    #
    # @raise    [Component::Options::Error::Invalid]
    #   If the requested reporter doesn't format the scan results as a String.
    def report_as( name, external_report = report )
        if !@reporters.available.include?( name.to_s )
            fail Component::Error::NotFound, "Reporter '#{name}' could not be found."
        end

        loaded = @reporters.loaded
        begin
            @reporters.clear

            if !@reporters[name].has_outfile?
                fail Component::Options::Error::Invalid,
                     "Reporter '#{name}' cannot format the audit results as a String."
            end

            outfile = "#{Options.paths.tmpdir}/#{generate_token}"
            @reporters.run( name, external_report, outfile: outfile )

            IO.binread( outfile )
        ensure
            File.delete( outfile ) if outfile && File.exists?( outfile )
            @reporters.clear
            @reporters.load loaded
        end
    end

    # @return    [Array<Hash>]
    #   Information about all available {Reporters}.
    def list_reporters( patterns = nil )
        loaded = @reporters.loaded

        begin
            @reporters.clear
            @reporters.available.map do |report|
                path = @reporters.name_to_path( report )
                next if patterns && !@reporters.matches_globs?( path, patterns )

                @reporters[report].info.merge(
                    options:   @reporters[report].info[:options] || [],
                    shortname: report,
                    path:      path,
                    author:    [@reporters[report].info[:author]].
                                   flatten.map { |a| a.strip }
                )
            end.compact
        ensure
            @reporters.clear
            @reporters.load loaded
        end
    end

end

end
end
end
