=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class State

# Stores and provides access to the state of the {Arachni::ElementFilter}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class ElementFilter

    TYPES = [:forms, :links, :link_templates, :cookies, :jsons, :xmls]

    TYPES.each do |type|
        attr_reader type
    end

    def initialize
        TYPES.each do |type|
            instance_variable_set "@#{type}",
                                  Support::LookUp::HashSet.new( hasher: :persistent_hash )
        end
    end

    def statistics
        TYPES.inject({}) { |h, type| h.merge!( type => send(type).size) }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/sets", Marshal.dump( self ) )
    end

    def self.load( directory )
        Marshal.load( IO.binread( "#{directory}/sets" ) )
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        TYPES.map { |type| send(type).hash }.hash
    end

    def clear
        TYPES.each { |type| send(type).clear }
    end

end

end
end
