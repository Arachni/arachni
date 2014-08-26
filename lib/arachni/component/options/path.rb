=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::Path < Arachni::Component::Options::Base

    def valid?
        return false if !super
        File.exists?( effective_value )
    end

    def type
        :path
    end

end
