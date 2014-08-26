=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# The namespace under which all reporters exist.
module Reporters
end

module Reporter

# Holds and manages {Reporters}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Manager < Arachni::Component::Manager
    NAMESPACE = Arachni::Reporters

    def initialize
        super( Arachni::Options.paths.reporters, NAMESPACE )
    end

    # @param  [Symbol, String]  name
    # @param  [Report]          report
    # @param  [Hash]            options
    #
    # @see Report
    def run( name, report, options = {} )
        exception_jail false do
            self[name].new( report, prepare_options( name, self[name], options ) ).tap(&:run)
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
