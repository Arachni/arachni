=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Parser
module SAX
class Document < Ox::Sax

    class Stop < Exception
    end

    require_relative 'with_nodes'
    require_relative 'element'

    include WithNodes

    def initialize( options = {} )
        super()

        @whitelist     = Set.new
        @stop_on_first = Set.new

        if options[:whitelist]
            @whitelist.merge options[:whitelist].map { |e| e.to_s.downcase }
        end

        if options[:stop_on_first]
            @stop_on_first.merge options[:stop_on_first]
        end

        @current_node = self
    end

    def name
        :document
    end

    def start_element( name )
        name = name.downcase

        # We were instructed to stop on the first sight of the previous element
        # but came across this one before it closed.
        fail Stop if @stop

        if stop?( name )
            @stop = true
        end

        e = Element.new( name )

        e.document = self
        @current_node << e
        @current_node = e
    end

    def end_element( name )
        name = name.downcase

        # Finished parsing the desired element, abort.
        fail Stop if stop?( name )

        close_node @current_node

        @current_node = @current_node.parent
    end

    def attr( name, value )
        name = name.downcase
        @current_node[name] = value if @current_node != self
    end

    def text( value )
        value.strip!
        @current_node << value
    end

    def comment( value )
        @current_node << Element.new( :comment ).tap { |e| e.value = value }
    end

    def to_html( indentation = 2, level = 0 )
        html = "<!DOCTYPE html>\n"
        children.each do |child|
            html << (child.is_a?( String ) ?
                child :
                child.to_html( indentation, level ))
        end
        html << "\n"
    end

    # def error( message, line, column )
    #     p "#{__method__} #{message} #{line} #{column}"
    # end

    def whitelisted?( name )
        return true if @whitelist.empty?

        @whitelist.include?( name.to_s )
    end

    def stop?( name )
        return false if @stop_on_first.empty?

        @stop_on_first.include?( name.to_s )
    end

end
end
end
end
