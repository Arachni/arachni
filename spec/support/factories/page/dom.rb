Factory.define :dom_data do
    {
        skip_states: Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 },
        transitions: [Factory[:transition]],
        data_flow_sink:        [
            data:  ['stuff'],
            trace: [
                [
                    function: 'onClick',
                    source:   "function onClick(some, arguments, here) {\n                _16744290dd4cf3a3d72033b82f11df32f785b50239268efb173ce9ac269714e5.send_to_sink(1);\n                return false;\n            }",
                    line:     202,
                    arguments: %w(some-arg arguments-arg here-arg)
                ]
            ]
        ],
        execution_flow_sink:   [
            data:  ['stuff2'],
            trace: [
                [
                    function: 'onClick2',
                    source:   "function onClick2(some, arguments, here) {\n                _16744290dd4cf3a3d72033b82f11df32f785b50239268efb173ce9ac269714e5.send_to_sink(1);\n                return false;\n            }",
                    line:     203,
                    arguments: %w(some-arg arguments-arg here-arg)
                ]
            ]
        ]
    }
end

Factory.define :dom do
    Factory[:page].dom
end
