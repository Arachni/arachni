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

#
# Arachni::Report::Manager class
#
# Holds and manages the registry of the reports.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < Arachni::Component::Manager
    include Utilities
    extend  Utilities

    NAMESPACE = Arachni::Reports

    def initialize( opts )
        super( opts.dir['reports'], NAMESPACE )
        @opts = opts
    end

    #
    # Takes care of report execution
    #
    # @see AuditStore
    #
    # @param  [AuditStore]  audit_store
    #
    def run( audit_store, run_afr = true )
        if run_afr
            # run the default report first
            run_one( 'afr', audit_store.deep_clone )
            delete( 'afr' )
        end

        loaded.each do |name|
            exception_jail( false ){ run_one( name, audit_store.deep_clone ) }
        end
    end

    def run_one( name, audit_store, opts = {} )
        report = self[name].new( audit_store.deep_clone,
            prep_opts( name, self[name], opts.empty? ? @opts.reports[name] : opts ) )

        report.run
        report
    end

    def self.reset
        remove_constants( NAMESPACE )
    end
    def reset
        self.class.reset
    end

    private
    def paths
        Dir.glob( File.join( "#{@lib}", "*.rb" ) ).reject { |path| helper?( path ) }
    end
end

end
end
