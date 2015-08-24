=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'auditable'

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Analyzable
    # Load and include all available analysis/audit techniques.
    Dir.glob( File.dirname( __FILE__ ) + '/analyzable/*.rb' ).each { |f| require f }

    include Signature
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
