=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides a {Arachni::Check::Manager} and related helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
                next if patterns && !@checks.matches_globs?( path, patterns )

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

    def run_checks( checks, page )
        ran = false
        checks.values.each do |check|
            ran = true if check_page( check, page )
        end
        harvest_http_responses if ran
        ran
    end

    # Passes a page to the check and runs it.
    # It also handles any exceptions thrown by the check at runtime.
    #
    # @param    [Check::Base]   check
    #   Check to run.
    # @param    [Page]    page
    def check_page( check, page )
        ps = page.platforms.to_a

        # If we've been given platforms which the check doesn't support don't
        # even bother running it.
        if !check.supports_platforms?( ps )
            print_info "Check #{check.shortname} does not support: #{ps.join( ' + ' )}"
            return false
        end

        begin
            @checks.run_one( check, page )
        rescue => e
            print_error "Error in #{check.to_s}: #{e.to_s}"
            print_error "Page: #{page.dom.url}"
            print_error_backtrace e
            false
        end
    end

end

end
end
end
