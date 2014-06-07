=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# The namespace under which all reports exist.
module Reports
end

module Report

# Holds and manages {Reports}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < Arachni::Component::Manager
    NAMESPACE = Arachni::Reports

    def initialize
        super( Arachni::Options.paths.reports, NAMESPACE )
    end

    # @param  [Symbol, String]  name
    # @param  [ScanReport]      scan_report
    # @param  [Hash]            options
    #
    # @see ScanReport
    def run( name, scan_report, options = {} )
        exception_jail false do
            self[name].new(
                scan_report,
                prepare_options( name, self[name], options )
            ).tap(&:run)
        end
    end

    def self.reset
        remove_constants( NAMESPACE )
    end
    def reset
        self.class.reset
    end

    private

    def paths
        Dir.glob( File.join( "#{@lib}", '*.rb' ) ).reject { |path| helper?( path ) }
    end

end

end
end
