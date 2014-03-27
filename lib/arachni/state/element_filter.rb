=begin
Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
All rights reserved.
=end

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ElementFilter

    # @return   [Support::LookUp::HashSet]
    attr_reader :forms

    # @return   [Support::LookUp::HashSet]
    attr_reader :links

    # @return   [Support::LookUp::HashSet]
    attr_reader :cookies

    def initialize
        @forms   = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @links   = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @cookies = Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def clear
        forms.clear
        links.clear
        cookies.clear
    end

end

end
end
