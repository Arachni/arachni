=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities
module WithAuditor

# Delegate output related methods to the {WithAuditor#auditor}.
module Output
    extend Forwardable

    [:debug?, :print_error, :print_status, :print_info, :print_line, :print_ok,
    :print_bad, :print_debug, :print_debug_backtrace, :print_error_backtrace
    ].each do |method|
        def_delegator :auditor, :with_browser_cluster
        define_method method do |*args|
            return if orphan?
            auditor.send( method, *args )
        end
    end

end

end
end
end
