=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithNode

    # @return   [String]
    #   HTML code for the element.
    attr_accessor :html

    def initialize( options )
        super
        self.html = options[:html].freeze
    end

    def html=( s )
        @html = s.freeze
    end

    # @return [Nokogiri::XML::Element]
    def node
        return if !@html
        Nokogiri::HTML.fragment( @html.dup ).children.first
    end

    def to_h
        super.merge( html: html )
    end

    def dup
        copy_with_node( super )
    end

    private

    def copy_with_node( other )
        other.html = html
        other
    end

end

end
end
