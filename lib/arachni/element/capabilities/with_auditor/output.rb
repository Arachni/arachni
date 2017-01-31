=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'forwardable'

module Arachni
module Element::Capabilities
module WithAuditor

# Delegate output related methods to the {WithAuditor#auditor}.
module Output
    extend ::Forwardable

    def_delegator :auditor, :with_browser_cluster

    [ :debug?, :print_error, :print_status, :print_verbose, :print_info,
      :print_line, :print_ok, :print_bad, :print_debug, :print_debug_backtrace,
      :print_error_backtrace, :print_debug_level_1, :print_debug_level_2,
      :print_debug_level_3, :print_debug_level_4, :print_debug_level_5,
      :debug_level_1?, :debug_level_2?, :debug_level_3?, :debug_level_4?,
      :debug_level_5?, :print_exception, :print_debug_exception ].each do |method|
        define_method method do |*args|
            (orphan? ? UI::Output : auditor).send( method, *args )
        end
    end

end

end
end
end
