=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element
class Path < Base

    def initialize( page )
        super url: page.url
    end

end
end
