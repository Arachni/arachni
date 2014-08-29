require 'spec_helper'

describe 'WAVSEP false-positive SQL injection' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'SQL Injection' => {
                url:        "SQL-Injection/SInjection-FalsePositives-#{http_method}/",
                checks:     'sql_injection*',
                vulnerable: []
            }
        }
    end

    easy_test
end
