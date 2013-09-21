=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Rack applications.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
