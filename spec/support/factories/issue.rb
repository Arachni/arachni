Factory.define :issue_data do
    {
        name:            "Check name \xE2\x9C\x93",
        description:     'Issue description',
        vector:          Factory[:passive_vector],
        response:        Factory[:response],
        platform_name:   :unix,
        platform_type:   :os,
        references:      {
            'Title' => 'http://some/url'
        },
        cwe:             1,
        severity:        Arachni::Severity::HIGH,
        remedy_guidance: 'How to fix the issue.',
        remedy_code:     'Sample code on how to fix the issue',
        tags:            %w(these are a few tags),
        remarks:         { the_dude: [ 'Hey!' ] },
        signature:       /some regexp/,
        proof:           "string matched by '/some regexp/'",
        check:           {
            name:        'Test check',
            description: 'Test description',
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1',
            targets:     {
                'Generic' => 'all'
            },
            elements:    [
                Arachni::Element::Link,
                Arachni::Element::Form
            ],
            shortname:   'test'
        }
    }
end

Factory.define :issue do
    Arachni::Issue.new( Factory[:issue_data] )
end
Factory.alias :passive_issue, :issue
Factory.alias :trusted_issue, :issue

Factory.define :active_issue do
    Factory[:passive_issue].tap { |i| i.vector = Factory[:active_vector] }
end

Factory.define :untrusted_issue do
    Factory[:trusted_issue].tap { |i| i.trusted = false }
end

Factory.define :issue_empty do
    Arachni::Issue.new( vector: Factory[:vector] )
end

Factory.define :issue_with_variations do
    root = Factory[:active_issue].with_variations

    10.times do |i|
        root.variations << Factory[:active_issue].as_variation.tap do |issue|
            issue.vector.affected_input_value = i.to_s
            issue.vector.seed                 = i.to_s
        end
    end

    root
end
