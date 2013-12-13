Factory.define :audit_store_data do
    {
        options:  Arachni::Options.to_h,
        sitemap:  [Arachni::Options.url],
        issues:   (0..10).map do |i|
            [
                Factory[:passive_issue].tap { |issue| issue.vector.action += i.to_s },
                Factory[:active_issue].tap { |issue| issue.vector.action += i.to_s }
            ]
        end.flatten,
        plugins:  {
            'plugin_name' => {
                results: 'stuff',
                options: [
                    Arachni::Component::Options::Enum.new(
                        'some_name',
                        [ false, 'Some description.', 'default_value',
                                      [ 'available', 'values', 'go', 'here' ]
                        ]
                    )
                ]
            }
        }
    }
end

Factory.define :audit_store do
    Arachni::AuditStore.new Factory[:audit_store_data]
end

Factory.define :audit_store_empty do
    Arachni::AuditStore.new
end
