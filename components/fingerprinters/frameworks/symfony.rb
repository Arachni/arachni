=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Symfony Framework cookies.
#
# @author Tomas Dobrotka <tomas@dobrotka.sk>
#
# @version 0.1
class Symfony < Platform::Fingerprinter

    def run
        if cookies.include?( 'symfony' )
            platforms << :php << :symfony
        end
    end

end

end
end
