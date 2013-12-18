=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end


module Arachni

lib = Options.dir['lib']
require lib + 'rpc/server/base'
require lib + 'rpc/client/browser'
require lib + 'processes'
require lib + 'framework'

module RPC
class Server

class Browser

# Provides a remote {Arachni::Browser} worker allowing to off-load the
# overhead of DOM/JS/AJAX analysis to a separate process.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Peer < Arachni::Browser

    attr_reader :master

    def initialize( options )
        @js_token = options.delete( :js_token )
        @master   = options.delete( :master )

        # Don't store pages if there's a master, we'll be sending them to him
        # as soon as they're logged.
        super options.merge( store_pages: @master.nil? )

        start_capture

        return if !@master

        on_response do |response|
            @master.push_to_sitemap( response.url, response.code ){}
        end

        on_new_page do |page|
            @master.handle_page( page ){}
        end
    end

    # Returns a token specified in {#initialize} instead of generating a random
    # one.
    #
    # Used by {BrowserCluster} to have all its workers share the same token to
    # avoid clashes between peers when namespacing the JS override code.
    #
    # @see Browser#js_token
    def js_token
        return super if !master
        @js_token
    end

    # Let the master handle deduplication of operations.
    #
    # @see Browser#skip?
    def skip?( *args )
        return super( *args ) if !master
        master.skip? *args
    end

    # Let the master know that the given operation should be skipped in
    # the future.
    #
    # @see Browser#skip
    def skip( *args )
        return super( *args ) if !master
        master.skip *args
    end

    # We change the default scheduling to distribute elements and events
    # to all available browsers ASAP, instead of building a list and then
    # consuming it, since we're don't have to worry about messing up our
    # page's state in this setup.
    #
    # @see Browser#trigger_events
    def trigger_events
        return !!super if !master

        root_page = to_page

        each_element_with_events do |info|
            info[:events].each do |name, _|
                distribute_event( root_page, info[:index], name.to_sym )
            end
        end

        true
    end

    # Direct the distribution to the master and let it take it from there.
    #
    # @see Browser#distribute_event
    def distribute_event( *args )
        return !!super( *args ) if !master

        master.analyze args
        true
    end

end
end
end
end
end
