Factory.define :header, class: Arachni::Element::Header,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 },
               }
