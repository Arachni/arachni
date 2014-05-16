Factory.define :link_template, class: Arachni::Element::LinkTemplate,
               options: {
                   url:      'http://test.com/input1/value1/input2/value2',
                   template: /input1\/(?<input1>\w+)\/input2\/(?<input1>\w+)/
               }
