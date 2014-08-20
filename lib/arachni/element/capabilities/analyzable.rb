=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

require_relative 'auditable'

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Analyzable
    include Auditable

    # Load and include all available analysis/audit techniques.
    Dir.glob( File.dirname( __FILE__ ) + '/analyzable/*.rb' ).each { |f| require f }

    include Taint
    include Timeout
    include Differential

    # Empties the de-duplication/uniqueness look-up table.
    #
    # Unless you're sure you need this, set the :redundant flag to true
    # when calling audit methods to bypass it.
    def Analyzable.reset
        Differential.reset
        Timeout.reset
    end
    reset

    def self.has_timeout_candidates?
        Timeout.has_candidates?
    end

    def self.timeout_audit_run
        Timeout.run
    end

end

end
end
