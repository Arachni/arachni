require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
        options.audit :forms

        framework.checks.load :common_files
    end

    it 'marks issues with too similar response bodies as needing manual verification and add remarks' do
        run
        framework.auditstore.issues.each do |issue|
            issue.variations.map( &:verification ).uniq == [true]
            issue.variations.first.remarks[:meta_analysis].should be_true
        end
    end

end
