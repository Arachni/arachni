=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

#
# The namespace under which all reports exist.
#
module Reports
end

module Report

# Holds and manages the registry of the reports.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < Arachni::Component::Manager
    NAMESPACE = Arachni::Reports

    def initialize
        super( Arachni::Options.paths.reports, NAMESPACE )
    end

    # @param  [Symbol, String]  name
    # @param  [AuditStore]      audit_store
    # @param  [Hash]             options
    #
    # @see AuditStore
    def run( name, audit_store, options = {} )
        exception_jail false do
            report = self[name].new( audit_store, prep_opts( name, self[name], options ) )
            report.run
            report
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
