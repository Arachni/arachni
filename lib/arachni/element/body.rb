=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element
class Body < Base

    def initialize( page )
        super url: page.url, method: page.request.method
    end

end
end
