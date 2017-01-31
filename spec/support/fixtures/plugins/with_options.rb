=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
