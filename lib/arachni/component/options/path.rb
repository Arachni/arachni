=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Component::Options::Path < Arachni::Component::Options::Base

    def valid?
        return false if !super
        File.exists?( effective_value )
    end

    def type
        :path
    end

end
