=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Path < Arachni::Component::Options::Base

    def valid?
        return false if !super
        return true if value.empty?
        File.exists?( value )
    end

    def type
        'path'
    end

end
