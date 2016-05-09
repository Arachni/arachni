=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Parser
module SAX
module WithNodes
module Locate
module LookUp

    def initialize
        super()

        @lookup_tables = {
            comments:                    {},
            by_name:                     {},
            by_attribute_name:           {},
            by_attribute_name_and_value: {}
        }
    end

    def push_child( child )
        (@lookup_tables[:by_name][child.name.to_sym] ||= []) << child
    end

    def close_node( node )
        node.attributes.each do |name, value|
            (node.parent.lookup_tables[:by_attribute_name][name.to_sym] ||= []) << node

            k = [name.downcase.to_sym, value.downcase].hash
            (node.parent.lookup_tables[:by_attribute_name_and_value][k] ||= []) << node
        end

        node.parent.update_lookup_tables( node.lookup_tables )
    end

    def update_lookup_tables( lookup_tables )
        lookup_tables.each do |type, groups|
            groups.each do |key, nodes|
                @lookup_tables[type][key] ||= []
                @lookup_tables[type][key] |= nodes
            end
        end
    end

    def lookup_tables
        @lookup_tables
    end

    def descendants
        @lookup_tables[:by_name].values
    end

    def nodes_by_name( name )
        fail_if_not_in_whitelist( name )

        @lookup_tables[:by_name][name.to_sym] || []
    end

    def nodes_by_names( names )
        names.map { |n| nodes_by_name( n ) }.flatten
    end

    def nodes_by_attribute_name( name )
        @lookup_tables[:by_attribute_name][name.to_sym] || []
    end

    def nodes_by_attribute_name_and_value( name, value )
        k = [name.downcase.to_sym, value.downcase].hash
        @lookup_tables[:by_attribute_name_and_value][k] || []
    end

end
end
end
end
end
end
