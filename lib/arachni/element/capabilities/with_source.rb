=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithSource

    class Error < Arachni::Element::Error
        class MissingSource < Error
        end
    end

    # @return   [String]
    #   Source for the element.
    attr_accessor :source

    def initialize( options )
        super
        self.source = options[:source]
    end

    def source=( s )
        @source = (s ? s.strip : s.freeze )
    end

    def to_h
        super.merge( source: source )
    end

    def to_rpc_data
        super.merge( 'source' => @source )
    end

    def dup
        copy_with_source( super )
    end

    private

    def copy_with_source( other )
        other.source = @source
        other
    end

end

end
end
