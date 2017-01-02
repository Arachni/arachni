=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Rails resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.1
class Rails < Platform::Fingerprinter

    IDs = %w(rails)

    def run
        headers.keys.each do |header|
            return update_platforms if header.start_with?( 'x-rails' )
        end

        IDs.each do |id|
            next if !server_or_powered_by_include? id

            return update_platforms
        end

        if cookies.include?( '_rails_admin_session' )
            update_platforms
        end
    end

    def update_platforms
        platforms << :ruby << :rack << :rails
    end

end

end
end
