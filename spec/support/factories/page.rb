Factory.define :page do
    Arachni::Page.new(
        response: Factory[:response],
        dom:      Factory[:dom_data],
        metadata: { stuf: 'blah' }
    )
end
