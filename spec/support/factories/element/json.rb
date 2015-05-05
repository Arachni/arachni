Factory.define :json, class: Arachni::Element::JSON,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 }
               }
