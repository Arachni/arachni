=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_auditor/output'

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithAuditor
    include Output

    # Sets the auditor for this element.
    #
    # The auditor provides its output, HTTP and issue logging interfaces.
    #
    # @return   [Arachni::Check::Auditor]
    attr_accessor :auditor

    # Removes the {#auditor} from this element.
    def remove_auditor
        self.auditor = nil
    end

    # Removes the associated {#auditor}.
    def prepare_for_report
        super if defined? super
        remove_auditor
    end

    # @return   [Bool]
    #   `true` if it has no auditor, `false` otherwise.
    def orphan?
        !auditor
    end

    def dup
        copy_with_auditor( super )
    end

    def marshal_dump
        super.tap { |h| h.delete :@auditor }
    end

    private

    def copy_with_auditor( other )
        other.auditor = self.auditor
        other
    end

end

end
end
