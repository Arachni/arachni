require 'spec_helper'

describe 'WAVSEP false-positive unvalidated redirect' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Unvalidated redirect' => {
                url:        "Unvalidated-Redirect/Redirect-FalsePositives-#{http_method}/",
                checks:     [:unvalidated_redirect],
                vulnerable: []
            }
        }
    end

    easy_test
end
