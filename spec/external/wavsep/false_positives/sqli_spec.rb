require 'spec_helper'

describe 'WAVSEP false-positive SQL injection' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'SQL Injection' => {
                url:        "SInjection-FalsePositives-#{http_method}/",
                modules:    'sqli*',

                # I maintain that these should be logged **but** be flagged as
                # untrusted.
                vulnerable: [
                    'Case07-FalsePositiveInjectionInLogin-PsAndIv-500ErrorOnUnrelatedSyntaxError.jsp',
                    'Case08-FalsePositiveInjectionInLogin-PsAndIv-200ErrorOnUnrelatedSyntaxError.jsp'
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
