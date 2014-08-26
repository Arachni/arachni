=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Floating point option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::Float < Arachni::Component::Options::Base

    def normalize
        Float( effective_value ) rescue nil
    end

    def valid?
        super && normalize
    end

    def type
        :float
    end

end
