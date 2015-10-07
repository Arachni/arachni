Factory.define :ui_form, class: Arachni::Element::UIForm,
               options: {
                   url:          'http://test.com',
                   source:       '<button id="myname" />',
                   method:       'click',
                   inputs:       { 'my-input' => 'stuff' },
                   opening_tags: {
                       'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
                   }
               }

Factory.define :ui_form_dom do
    Factory[:ui_form].dom
end
