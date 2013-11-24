=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element
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
            # find ourselves
            f = self.class.from_response( res ).select { |f| f.id == id_from( :original ) }.first

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

end
end
