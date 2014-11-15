=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

module Check

    # @return   [Arachni::Check::Manager]
    attr_reader :checks

    def initialize
        super
        @checks = Arachni::Check::Manager.new( self )
    end

    # @return    [Array<Hash>]
    #   Information about all available {Checks}.
    def list_checks( patterns = nil )
        loaded = @checks.loaded

        begin
            @checks.clear
            @checks.available.map do |name|
                path = @checks.name_to_path( name )
                next if !list_check?( path, patterns )

                @checks[name].info.merge(
                    shortname: name,
                    author:    [@checks[name].info[:author]].
                                   flatten.map { |a| a.strip },
                    path:      path.strip,
                    platforms: @checks[name].platforms,
                    elements:  @checks[name].elements
                )
            end.compact
        ensure
            @checks.clear
            @checks.load loaded
        end
    end

    private

    # Passes a page to the check and runs it.
    # It also handles any exceptions thrown by the check at runtime.
    #
    # @param    [Check::Base]   check
    #   Check to run.
    # @param    [Page]    page
    def check_page( check, page )
        begin
            @checks.run_one( check, page )
        rescue => e
            print_error "Error in #{check.to_s}: #{e.to_s}"
            print_error_backtrace e
            false
        end
    end

    def list_check?( path, patterns = nil )
        regexp_array_match( patterns, path )
    end

end

end
end
end
