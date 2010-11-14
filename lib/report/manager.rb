=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# The namespace under which all modules exist
#
module Reports

    #
    # Resets the namespace unloading all module classes
    #
    def self.reset
        constants.each {
            |const|
            remove_const( const )
        }
    end
end

module Report

#
# Arachni::Report::Manager class
#
# Holds and manages the registry of the reports.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr> <br/>
# @version: 0.2
#
class Manager < Arachni::ComponentManager

    # the extension of the Arachni Framework Report files
    EXTENSION   = '.afr'

    def initialize( opts )
        super( opts.dir['reports'], Arachni::Reports )
        @opts = opts
    end

    #
    # Takes care of report execution
    #
    # @see AuditStore
    #
    # @param  [AuditStore]  audit_store
    #
    def run( audit_store )
        self.each {
            |name, report|

            #
            # if the user hasn't selected a filename for the report
            # choose one for him
            #
            # You might think that it's stupid putting this inside the loop
            # but it isn't.
            # If 2 reports use the same extension they will overwrite each other's files.
            #
            if( !@opts.repsave || @opts.repsave.size == 0 )
                @opts.repsave = URI.parse( audit_store.options['url'] ).host +
                    '-' + Time.now.to_s
            end

            new_rep = report.new( audit_store.deep_clone, @opts.repopts,
                            @opts.repsave + EXTENSION )

            new_rep.run( )
        }

        return @opts.repsave
    end

    def self.reset
        Arachni::Reports.reset
    end

    def extension
        return EXTENSION
    end

end

end
end
