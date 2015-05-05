Factory.define :form, class: Arachni::Element::Form,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 }
               }

Factory.define :form_dom, class: Arachni::Element::Form,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 },
                   source: '<form><inputs name="stuff" value="1">'
               }
