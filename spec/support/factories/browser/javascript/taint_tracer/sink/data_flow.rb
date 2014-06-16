Factory.define :data_flow_data do
    {
        function:               Factory[:called_function],
        object:                 '[object DOMWindow]',
        tainted_value:          Factory[:called_function].arguments.first,
        tainted_argument_index: 0,
        taint:                  Factory[:called_function].arguments.first,
        trace:                  [ Factory[:frame] ]
    }
end

Factory.define :data_flow do
    Arachni::Browser::Javascript::TaintTracer::Sink::DataFlow.new( Factory[:data_flow_data] )
end
