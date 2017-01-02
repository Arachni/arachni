=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'document'

module Arachni
class Parser
class SAX < Ox::Sax

    class Stop < Exception
    end

    attr_reader :document

    def initialize( options = {} )
        super()

        @document = Document.new

        @stop_on_first = Set.new
        @stop_on_first.merge( options[:stop_on_first] ) if options[:stop_on_first]

        @current_node = @document
    end

    def start_element( name )
        # We were instructed to stop on the first sight of the previous element
        # but came across this one before it closed.
        fail Stop if @stop
        @stop = stop?( name )

        e = Nodes::Element.new( name )

        e.document     = @document
        @current_node << e
        @current_node  = e
    end

    def end_element( name )
        # Finished parsing the desired element, abort.
        fail Stop if @stop

        @current_node = @current_node.parent
    end

    def attr( name, value )
        return if !@current_node.respond_to?( :attributes )

        @current_node.attributes[name] = value
    end

    def text( value )
        @current_node << Nodes::Text.new( value )
    end

    def comment( value )
        @current_node << Nodes::Comment.new( value )
    end

    private

    def stop?( name )
        return false if @stop_on_first.empty?

        @stop_on_first.include?( name.to_s.downcase )
    end

end
end
end
