require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
        options.audit.element :forms

        framework.checks.load :common_files
    end

    context 'when issues have similar response bodies' do
        it 'marks them as untrusted and adds remarks' do
            run
            framework.report.issues.each do |issue|
                issue.variations.map( &:untrusted? ).uniq == [true]
                expect(issue.variations.first.remarks[:meta_analysis]).to be_truthy
            end
        end
    end

end
