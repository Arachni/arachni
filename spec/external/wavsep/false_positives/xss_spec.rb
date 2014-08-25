require 'spec_helper'

describe 'WAVSEP false-positive XSS' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Reflected Cross Site Scripting' => {
                url:     "Reflected-XSS/RXSS-FalsePositives-#{http_method}/",
                checks:  'xss*',
                vulnerable: []
            }
        }
    end

    easy_test
end
