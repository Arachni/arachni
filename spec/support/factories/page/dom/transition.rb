Factory.define :transition do
    Factory[:completed_transition]
end

Factory.define :running_transition do
    Arachni::Page::DOM::Transition.new( :page, :load, extra: :options )
end

Factory.define :completed_transition do
    Arachni::Page::DOM::Transition.new( :page, :load,
        extra: {
            options: {
                stuff: 'here'
            }
        }
    ).complete
end

Factory.define :empty_transition do
    Arachni::Page::DOM::Transition.new
end

Factory.define :empty_transition do
    Arachni::Page::DOM::Transition.new
end

Factory.define :input_transition do
    Arachni::Page::DOM::Transition.new(
        Arachni::Browser::ElementLocator.new(
            tag_name:   :input,
            attributes: {
                "oninput" => "handleoninput();",
                "id" => "my-input",
                "name" => "my-input"
            }
        ),
        :input,
        options: {
            value: "<some_dangerous_input_a9838b473d1f6db80b6342d1c61f9fa2></some_dangerous_input_a9838b473d1f6db80b6342d1c61f9fa2> "
        }
    )
end
