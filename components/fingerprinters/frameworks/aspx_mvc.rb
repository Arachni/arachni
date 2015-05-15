=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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
        return update_platforms if cookies.include?( ANTI_CSRF_NONCE )

        page.forms.each do |form|
            form.inputs.each do |k, v|
                return update_platforms if k.downcase.include? ANTI_CSRF_NONCE
            end
        end

        if (headers.keys & HEADER_FIELDS).any?
            update_platforms
        end
    end

    def update_platforms
        platforms << :asp << :aspx << :windows << :aspx_mvc
    end

end

end
end
