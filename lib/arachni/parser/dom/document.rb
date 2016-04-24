=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Ox
class Node

    def to_html
        Ox.dump self
    end

end
end

module Arachni
class Parser
class Document

    # @param    [Ox::Document]  document
    def initialize( document )
        @document = document
    end

    def comments
        @comments ||= begin
            n = []
            traverse( Ox::Comment ) { |e| n << e }
            n
        end
    end

    def traverse( klass = nil, &block )
        return if !@document
        traverser @document.nodes, klass, &block
    end

    def descendants
        @nodes ||= begin
            n = []
            traverse { |e| n << e }
            n
        end
    end

    def children
        @document.nodes
    end

    def nodes_by_name( name )
        @nodes_by_name ||= {}
        @nodes_by_name[name.to_s.hash] ||=
            @document.locate( name.to_s ) | @document.locate( "*/#{name}" )
    end

    def nodes_by_names( names )
        @nodes_by_name ||= {}
        @nodes_by_name[names.hash] ||= names.map { |n| nodes_by_name( n ) }.flatten
    end

    def nodes_by_attribute_name( name )
        @nodes_by_attribute_name ||= {}
        @nodes_by_attribute_name[name.to_s.hash] ||= begin
            n = []
            traverse do |e|
                next if !e.respond_to?(:attributes) || !e.attributes.include?( name )
                n << e
            end
            n
        end
    end

    def nodes_by_attribute_name_and_value( name, value )
        @nodes_by_attribute_name_and_value ||= {}
        @nodes_by_attribute_name_and_value[[name.to_s, value].hash] ||= begin
            n = []
            traverse do |e|
                next if e[name] != value
                n << e
            end
            n
        end
    end

    private

    def traverser( nodes, klass = nil, &block )
        nodes.each do |node|
            block.call( node ) if !klass || node.is_a?( klass )

            next if !node.respond_to?( :nodes )

            traverser node.nodes, klass, &block
        end
    end

end
end
end
