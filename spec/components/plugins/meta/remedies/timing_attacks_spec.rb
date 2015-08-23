require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
        options.audit.elements :forms

        # this check uses the least amount of seeds, should save us some time
        framework.checks.load :os_cmd_injection_timing
    end

    context 'when issues have high response times' do
        it 'marks them as untrusted and adds remarks' do
            run

            checked = 0
            framework.report.issues.each do |issue|
                next if issue.affected_input_name != 'untrusted_input'

                checked += 1
                expect(issue).to be_untrusted
                expect(issue.remarks).to include :meta_analysis
            end

            expect(checked).to be > 0
        end
    end

end
