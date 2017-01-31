=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Capabilities::Refreshable

    # Refreshes the form's inputs and re-applies user updates.
    #
    # The way it works is by requesting the {Element::Base#url}, parsing the
    # response and updating the form with the fresh form's inputs.
    #
    # @param    [Hash]   http_opts
    #   HTTP options to pass to the request.
    # @param    [Block]  block
    #   If a block is given the request will be async and the block will be
    #   called with the updated form.
    #
    # @return   [Form]  self
    def refresh( http_opts = {}, &block )
        updated = nil
        http.get( url.to_s, http_opts.merge( mode: block_given? ? :async : :sync ) ) do |res|

            # Find the original version of self in the response.
            f = self.class.from_response( res ).
                find { |f| f.refresh_id == refresh_id }

            if !f
                block.call if block_given?
                next
            end

            # get user updates
            updates = changes
            # update the form's inputs with the fresh ones and re-apply the user changes
            updated = update( f.inputs ).update( updates )
            block.call( updated ) if block_given?
        end
        updated
    end

    # @return   [String]
    #   Unique string identifying this element while disregarding any applied
    #   runtime modifications (usually to its {Inputtable#inputs}).
    #
    #   Basically, a modified element and a fresh element should both return
    #   the same value while uniquely identifying the pair.
    #
    # @abstract
    def refresh_id
        "#{action}:#{type}:#{default_inputs.keys.sort}"
    end

end
end
