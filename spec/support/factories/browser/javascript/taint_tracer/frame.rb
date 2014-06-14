Factory.define :frame_data do
    {
        function: 'onClick',
        source:   "function onClick(some, arguments, here) {\n                _16744290dd4cf3a3d72033b82f11df32f785b50239268efb173ce9ac269714e5.send_to_sink(1);\n                return false;\n            }",
        line:     202,
        arguments: %w(some-arg arguments-arg here-arg)
    }
end

Factory.define :frame do
    Arachni::Browser::Javascript::TaintTracer::Frame.new( Factory[:frame_data] )
end
