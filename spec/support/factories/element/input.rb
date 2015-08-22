Factory.define :input, class: Arachni::Element::Input,
               options: {
                   url:    'http://test.com',
                   source: '<input id="myname" />',
                   method: 'input',
                   inputs: {
                       'myname' => ''
                   }
               }

Factory.define :input_dom do
    Factory[:input].dom
end
