Factory.define :issue_data do
    {
        name:            "Check name \xE2\x9C\x93",
        description:     'Issue description',
        vector:          Factory[:passive_vector],
        page:            Factory[:page],
        referring_page:  Factory[:page],
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1',
            targets:     {
                'Generic' => 'all'
            },
            elements:    [
                Arachni::Element::Link
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
