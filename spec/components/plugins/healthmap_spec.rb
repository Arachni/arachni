require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.url = url
        framework.options.audit.elements :links
        framework.checks.load :xss
    end

    def results
        <<YAML
---
map:
- without_issues: __URL__
- without_issues: __URL__safe
- with_issues: __URL__vuln
total: 3
without_issues: 2
with_issues: 1
issue_percentage: 33
YAML
    end

    it 'logs URLs with and without issues accordingly' do
        run

        results     = actual_results
        exp_results = expected_results

        actual_map   = results.delete( 'map' )
        expected_map = exp_results.delete( 'map' )

        expect(actual_map.select { |k, v| k == 'without_issues' }).to be_eql expected_map.select { |k, v| k == 'without_issues' }
        expect(actual_map.select { |k, v| k == 'with_issues' }).to be_eql expected_map.select { |k, v| k == 'with_issues' }

        expect(results).to be_eql exp_results
    end
end
