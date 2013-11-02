require 'spec_helper'

describe 'WAVSEP false-positive Local File Inclusion' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Local File Inclusion' => {
                url:        "LFI-FalsePositives-#{http_method}/",
                modules:    [ :file_inclusion, :path_traversal, :source_code_disclosure],

                # I maintain that these should be logged **but** be flagged as
                # untrusted.
                vulnerable: [
                    'Case05-LFI-FalsePositive-ContextStream-TextHtmlValidResponse-FilenameContext-WhiteList-OSPath-DefaultRelativeInput-NoPathReq-Read.jsp',
                    'Case06-LFI-FalsePositive-ContextStream-TextHtmlValidResponse-FilenameContext-TraversalRemovalAndWhiteList-OSPath-DefaultRelativeInput-NoPathReq-Read.jsp'
                ]
            }
        }
    end

    easy_test do
        @framework.modules.issues.each do |issue|
            issue.trusted?.should be_false
            issue.remarks.should include :auditor
        end
    end

end
