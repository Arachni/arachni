require 'spec_helper'

describe 'WAVSEP false-positive Remote File Inclusion' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Remote File Inclusion' => {
                url:        "RFI/RFI-FalsePositives-#{http_method}/",
                checks:     :rfi,
                vulnerable: []
            }
        }
    end

    easy_test
end
