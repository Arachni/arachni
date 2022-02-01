=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Default Symfony Framework cookie.
#
# @author Tomas Dobrotka <tomas@dobrotka.sk>
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Symfony < Platform::Fingerprinter

    def run
        return if !cookies.include?( 'symfony' )

        platforms << :php << :symfony
    end

end

end
end
