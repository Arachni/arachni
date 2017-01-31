=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Body < Base
    include Capabilities::WithAuditor

    def initialize( url )
        super url: url
        @initialization_options = url
    end

    # Matches an array of regular expressions against a string and logs the
    # result as an issue.
    #
    # @param    [Array<Regexp>]     patterns
    #   Array of regular expressions to be tested.
    # @param    [Block] block
    #   Block to verify matches before logging, must return `true`/`false`.
    def match_and_log( patterns, &block )
        [patterns].flatten.each do |pattern|
            auditor.page.body.scan( pattern ).flatten.uniq.compact.each do |proof|
                next if block_given? && !block.call( proof )

                auditor.log(
                    signature: pattern,
                    proof:     proof,
                    vector:    self
                )
            end
        end
    end

end
end
