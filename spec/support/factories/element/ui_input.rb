Factory.define :ui_input, class: Arachni::Element::UIInput,
               options: {
                   url:    'http://test.com',
                   source: '<input id="myname" />',
                   method: 'input',
                   inputs: {
                       'myname' => ''
                   }
               }

Factory.define :ui_input_dom do
    Factory[:ui_input].dom
end
