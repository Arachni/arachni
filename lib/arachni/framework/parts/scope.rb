=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides scope helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Scope

    # @return   [Bool]
    #   `true` if the {OptionGroups::Scope#page_limit} has been reached,
    #   `false` otherwise.
    def page_limit_reached?
        options.scope.page_limit_reached?( sitemap.size )
    end

    def crawl?
        options.scope.crawl? && options.scope.restrict_paths.empty?
    end

    # @return   [Bool]
    #   `true` if the framework can process more pages, `false` is scope limits
    #   have been reached.
    def accepts_more_pages?
        crawl? && !page_limit_reached?
    end

end

end
end
end
