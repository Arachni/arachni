Factory.define :transition do
    Factory[:completed_transition]
end

Factory.define :running_transition do
    Arachni::Page::DOM::Transition.new( { page: :load }, { extra: :options } )
end

Factory.define :completed_transition do
    Arachni::Page::DOM::Transition.new( { page: :load }, { extra: :options } ).complete
end

Factory.define :empty_transition do
    Arachni::Page::DOM::Transition.new
end
