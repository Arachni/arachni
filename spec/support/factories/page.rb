Factory.define :page do
    Arachni::Page.new(
        response: Factory[:response],
        dom:      Factory[:dom_data]
    # Load all elements to populate metadata and the like but clear the cache.
    ).tap(&:elements).tap(&:clear_cache)
end
