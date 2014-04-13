require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.url = url
        framework.opts.audit.elements :links
        framework.checks.load :xss
    end

    def results
        <<YAML
---
:map:
- :without_issues: __URL__
- :without_issues: __URL__safe
- :with_issues: __URL__vuln
:total: 4
:without_issues: 3
:with_issues: 1
:issue_percentage: 25
YAML
    end

    it 'logs URLs with and without issues accordingly' do
        run

        results     = actual_results
        exp_results = expected_results

        actual_map   = results.delete( :map )
        expected_map = exp_results.delete( :map )

        actual_map.select { |k, v| k == :without_issues }.should be_eql expected_map.select { |k, v| k == :without_issues }
        actual_map.select { |k, v| k == :with_issues }.should be_eql expected_map.select { |k, v| k == :with_issues }

        results.should be_eql exp_results
    end
end
