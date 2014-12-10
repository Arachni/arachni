=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithSource

    # @return   [String]
    #   Source for the element.
    attr_accessor :source

    def initialize( options )
        super
        self.source = options[:source].freeze
    end

    def source=( s )
        @source = (s ? s.recode.freeze : s)
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
        other.source = source
        other
    end

end

end
end
