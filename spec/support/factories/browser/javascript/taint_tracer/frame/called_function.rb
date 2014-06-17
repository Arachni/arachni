Factory.define :called_function_data do
    {
        name:      'stuff',
        source:    'function stuff(blah, blooh){ function ha(){} }',
        arguments: %w(blah-val blooh-val)
    }
end

Factory.define :called_function do
    Arachni::Browser::Javascript::TaintTracer::Frame::CalledFunction.new( Factory[:called_function_data] )
end
