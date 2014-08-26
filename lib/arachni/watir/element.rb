=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Watir
class Element

    def opening_tag
        html.match( /<#{tag_name}.*?>/im )[0]
    end

end
end
