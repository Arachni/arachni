=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Plugins::WithOptions < Arachni::Plugin::Base
    def self.info
        {
            name:        'Component',
            description: %q{Component with options},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            options:     [
                Options::String.new(
                    'req_opt',
                    required:    true,
                    description: 'Required option'
                ),
                Options::String.new(
                    'opt_opt',
                    description: 'Optional option'
                ),
                Options::MultipleChoice.new(
                    'default_opt',
                    description: 'Option with default value',
                    default:     'value',
                    choices:     ['value', 'value2']
                )
            ]
        }
    end
end
