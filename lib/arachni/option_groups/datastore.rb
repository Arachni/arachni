=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'ostruct'

module Arachni::OptionGroups

# Generic OpenStruct-based class for general purpose data storage.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
