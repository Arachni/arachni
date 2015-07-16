Factory.define :transition do
    Factory[:completed_transition]
end

Factory.define :running_transition do
    Arachni::Page::DOM::Transition.new( :page, :load, extra: :options )
end

Factory.define :completed_transition do
    Arachni::Page::DOM::Transition.new( :page, :load, stuff: 'here' ).complete
end

Factory.define :request_transition do
    Arachni::Page::DOM::Transition.new( 'http://test.com', :request )
end

Factory.define :empty_transition do
    Arachni::Page::DOM::Transition.new
end

Factory.define :empty_transition do
    Arachni::Page::DOM::Transition.new
end

Factory.define :page_load_with_cookies_transition do
    Arachni::Page::DOM::Transition.new(
        :page, :load,
        url: 'http://a-url.com/?myvar=my%20value',
        cookies: {
            'myname' => 'myvalue'
        }
    )
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
        value: "<some_dangerous_input_a9838b473d1f6db80b6342d1c61f9fa2></some_dangerous_input_a9838b473d1f6db80b6342d1c61f9fa2> "
    )
end

Factory.define :form_input_transition do
    Arachni::Page::DOM::Transition.new(
        Arachni::Browser::ElementLocator.new(
            tag_name:   :form,
            attributes: {
                "id" => "my-form",
                "name" => "my-form"
            }
        ),
        :submit,
        inputs: {
            'input-name' => "<some_dangerous_input_a9838b473d1f6db80b6342d1c61f9fa2></some_dangerous_input_a9838b473d1f6db80b6342d1c61f9fa2> "
        }
    )
end
