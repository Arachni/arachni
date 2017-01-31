=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Rack applications.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.2
class Rack < Platform::Fingerprinter

    SESSIONID = 'rack.session'

    def run
        return if !powered_by.include?( 'mod_rack' ) &&
            !headers.keys.find { |h| h.include? 'x-rack' } &&
            !cookies.include?( SESSIONID )

        platforms << :ruby << :rack
    end

end

end
end
