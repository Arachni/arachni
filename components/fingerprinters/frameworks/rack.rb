=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Rack applications.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Rack < Platform::Fingerprinter

    SESSIONID = 'rack.session'
    ID        = 'mod_rack'

    def run
        return if !cookies.include?( SESSIONID ) &&
            !server_or_powered_by_include?( ID )
        platforms << :ruby << :rack
    end

end

end
end
