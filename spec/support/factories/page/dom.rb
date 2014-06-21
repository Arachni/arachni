Factory.define :dom_data do
    {
        skip_states:         Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 },
        transitions:         [ Factory[:transition]],
        digest:              'stuff',
        data_flow_sinks:     [ Factory[:data_flow] ],
        execution_flow_sink: [ Factory[:execution_flow] ]
    }
end

Factory.define :dom do
    Factory[:page].dom
end
