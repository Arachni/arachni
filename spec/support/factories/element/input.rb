Factory.define :input, class: Arachni::Element::Input,
               options: {
                   url:    'http://test.com',
                   source: '<input id="myname" />',
                   method: 'input'
               }

Factory.define :input_dom do
    Factory[:input].dom
end
