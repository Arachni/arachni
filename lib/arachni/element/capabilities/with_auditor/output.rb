=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities
module WithAuditor

# Delegate output related methods to the {WithAuditor#auditor}.
module Output
    extend Forwardable

    [ :debug?, :print_error, :print_status, :print_verbose, :print_info,
      :print_line, :print_ok, :print_bad, :print_debug, :print_debug_backtrace,
      :print_error_backtrace, :print_debug_level_1, :print_debug_level_2,
      :print_debug_level_3, :debug_level_1?, :debug_level_2?, :debug_level_3?,
      :print_exception ].each do |method|
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
