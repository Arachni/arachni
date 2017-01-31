Factory.define :dom_data do
    {
        cookies:              [
            Arachni::Element::Cookie.new(
                url:    'http://test/dom',
                inputs: { 'name' => 'val' }
            )
        ],
        skip_states:          Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 },
        transitions:          [
            Factory[:page_load_with_cookies_transition].complete,
            Factory[:request_transition].complete,
            Factory[:input_transition].complete,
            Factory[:form_input_transition].complete
        ],
        digest:               'stuff',
        data_flow_sinks:      [ Factory[:data_flow] ],
        execution_flow_sinks: [ Factory[:execution_flow] ]
    }
end

Factory.define :dom do
    Factory[:page].dom
end
