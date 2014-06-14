Factory.define :data_flow_data do
    {
        function: 'stuff',
        source:   'function stuff( arg, arg2 ) {}',
        arguments: %w(some-arg arguments-arg),
        object:    '[object DOMWindow]',
        tainted:   'arguments-arg',
        taint:     'arguments',
        trace:    [ Factory[:frame] ]
    }
end

Factory.define :data_flow do
    Arachni::Browser::Javascript::TaintTracer::Sink::DataFlow.new( Factory[:data_flow_data] )
end
