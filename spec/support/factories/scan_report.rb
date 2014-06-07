Factory.define :scan_report_data do
    {
        options:  Arachni::Options.to_hash,
        sitemap:  { Arachni::Options.url => 200 },
        issues:   (0..10).map do |i|
            [
                Factory[:passive_issue].tap { |issue| issue.vector.action += i.to_s },
                Factory[:active_issue].tap { |issue| issue.vector.action += i.to_s }
            ]
        end.flatten,
        plugins:  {
            plugin_name: {
                results: 'stuff',
                options: [
                    Arachni::Component::Options::MultipleChoice.new(
                        'some_name',
                        description:  'Some description.',
                        default:      'default_value',
                        choices: %w(available values go here)
                    )
                ]
            }
        },
        start_datetime:  Time.now - 10_000,
        finish_datetime: Time.now
    }
end

Factory.define :scan_report do
    Arachni::ScanReport.new Factory[:scan_report_data]
end

Factory.define :scan_report_empty do
    Arachni::ScanReport.new
end
