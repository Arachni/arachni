require 'spec_helper'

describe 'WAVSEP false-positive XSS' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Reflected Cross Site Scripting' => {
                url:        "RXSS-FalsePositives-#{http_method}/",
                modules:    'xss*',
                vulnerable: []
            }
        }
    end

    easy_test
end
