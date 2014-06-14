Factory.define :execution_flow_data do
    {
        data:  ['arguments'],
        trace: [ Factory[:frame] ]
    }
end

Factory.define :execution_flow do
    Arachni::Browser::Javascript::TaintTracer::Sink::ExecutionFlow.new( Factory[:execution_flow_data] )
end
