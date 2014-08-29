require 'spec_helper'

describe 'WAVSEP false-positive Local File Inclusion' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Local File Inclusion' => {
                url:        "LFI/LFI-FalsePositives-#{http_method}/",
                checks:     [:file_inclusion, :path_traversal, :source_code_disclosure],
                vulnerable: []
            }
        }
    end

    easy_test
end
