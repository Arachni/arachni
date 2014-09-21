Factory.define :genericdom do
    Arachni::Element::GenericDOM.new(
        url:        Factory[:dom].url,
        transition: Factory[:input_transition]
    )
end
