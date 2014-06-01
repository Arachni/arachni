=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Watir
class Element

    def opening_tag
        html.match( /<#{tag_name}.*?>/im )[0]
    end

end
end
