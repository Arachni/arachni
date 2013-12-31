=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'ostruct'

module Arachni::OptionGroups

# Generic OpenStruct-based class for general purpose data storage.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Datastore < Arachni::OptionGroup

    def initialize
        @source = OpenStruct.new
    end

    def method_missing( method, *args, &block )
        @source.send( method, *args, &block )
    end

    def to_h
        @source.marshal_dump
    end

end
end
