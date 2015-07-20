=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Nette Framework cookies.
#
# @author Tomas Dobrotka <tomas@dobrotka.sk>
#
# @version 0.1
class Nette < Platform::Fingerprinter

    def run
        if cookies.include?( 'nette-browser' )
            platforms << :php << :nette
        end

        if server_or_powered_by_include?( 'Nette' )
            platforms << :php << :nette
        end


    end

end

end
end
