Factory.define :report_data do
    issues = Arachni::Data::Issues.new

    (0..10).map do |i|
        issues << Factory[:passive_issue].tap { |issue| issue.vector.action += i.to_s }
        issues << Factory[:active_issue].tap { |issue| issue.vector.action += i.to_s }
    end

    {
        seed:     Arachni::Utilities.random_seed,
        options:  Arachni::Options.to_hash,
        sitemap:  { Arachni::Options.url => 200 },
        issues:   issues,
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

Factory.define :report do
    Arachni::Report.new Factory[:report_data]
end

Factory.define :report_empty do
    Arachni::Report.new
end
