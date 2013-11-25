require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
        options.audit :forms

        # this check uses the least amount of seeds, should save us some time
        framework.checks.load :os_cmd_injection_timing
    end

    def results
        framework.auditstore.issues.map.with_index do |issue, idx|
            next if issue.var != 'untrusted_input'

            issue.variations.map( &:verification ).uniq == [true]
            issue.variations.first.remarks[:meta_analysis].should be_true

            {
                'hash'   => issue.digest,
                'index'  => idx + 1,
                'url'    => issue.url,
                'name'   => issue.name,
                'var'    => issue.var,
                'elem'   => issue.elem,
                'method' => issue.method
            }
        end.compact
    end

    easy_test
end
