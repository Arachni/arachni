Factory.define :xml, class: Arachni::Element::XML,
               options: {
                   url:    'http://test.com',
                   source: '<input>value</input>'
               }
