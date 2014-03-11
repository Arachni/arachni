=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
module Jobs

# Loads a {#resource} and {Browser#trigger_events explores} its DOM.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ResourceExploration < Job

    require_relative 'resource_exploration/result'
    require_relative 'resource_exploration/event_trigger'

    # @return [Page, String, HTTP::Response]
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    attr_accessor :resource

    def initialize( options )
        self.resource = options.delete(:resource)
        super options
    end

    # Loads a {#resource} and {Browser#trigger_events explores} its DOM.
    def run
        browser.on_new_page { |page| save_result( page: page ) }

        browser.load resource
        browser.trigger_events
    end

    def marshal_dump
        instance_variables.inject( {} ) do |h, iv|
            obj = instance_variable_get( iv )

            # Since we don't care about the caches (lazy-loaded elements and
            # such), clearing them makes serializing and un-serializing pages
            # **much** less resource consuming.
            if obj.is_a? Page
                obj = resource.dup
                obj.clear_caches
            end

            h[iv] = obj
            h
        end
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( k, v ) }
    end

    def dup
        super.tap { |j| j.resource = resource }
    end

    def clean_copy
        super.tap { |j| j.resource = nil }
    end

end

end
end
end
