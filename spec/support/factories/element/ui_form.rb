Factory.define :ui_form, class: Arachni::Element::UIForm,
               options: {
                   url:    'http://test.com',
                   source: '<button id="myname" />',
                   method: 'click'
               }

Factory.define :ui_form_dom do
    Factory[:ui_form].dom
end
