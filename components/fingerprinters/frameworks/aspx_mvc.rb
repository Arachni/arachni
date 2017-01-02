=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies ASP.NET MVC resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class ASPXMVC < Platform::Fingerprinter

    ANTI_CSRF_NONCE = '__requestverificationtoken'
    HEADER_FIELDS   = %w(x-aspnetmvc-version)

    def run
        # Naive but enough, I think.
        if html? && page.body =~ /input.*#{ANTI_CSRF_NONCE}/i
            return update_platforms
        end

        if (headers.keys & HEADER_FIELDS).any?
            return update_platforms
        end

        if cookies.include?( ANTI_CSRF_NONCE )
            update_platforms
        end
    end

    def update_platforms
        platforms << :asp << :aspx << :windows << :aspx_mvc
    end

end

end
end
