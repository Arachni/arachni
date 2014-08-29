require 'spec_helper'

describe 'WAVSEP false-positive obsolete-files' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Obsolete files' => {
                url:        "Obsolete-Files/ObsoleteFile-FalsePositives-#{http_method}/",
                checks:     [:backup_files, :backup_directories, :common_files, :common_directories],
                vulnerable: []
            }
        }
    end

    easy_test
end
