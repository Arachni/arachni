=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Mult-byte character string option.
#
###
class Arachni::Component::Options::String < Arachni::Component::Options::Base
    def type
        'string'
    end

    def normalize( value )
        if value =~ /^file:(.*)/
            path = $1
            begin
                value = File.read( path )
            rescue ::Errno::ENOENT, ::Errno::EISDIR
                value = nil
            end
        end
        value
    end

    def valid?( value = self.value )
        value = normalize( value )
        return false if empty_required_value?( value )
        super
    end
end
