require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.url = url
        framework.opts.audit :links
        framework.checks.load :xss
    end

    def results
        <<YAML
---
:map:
- :safe: __URL__
- :safe: __URL__safe
- :unsafe: __URL__vuln
:total: 4
:safe: 3
:unsafe: 1
:issue_percentage: 25
YAML
    end

    it 'logs safe and vuln URLs accordingly' do
        run

        results     = actual_results
        exp_results = expected_results

        actual_map   = results.delete( :map )
        expected_map = exp_results.delete( :map )

        actual_map.select { |k, v| k == :safe }.should be_eql expected_map.select { |k, v| k == :safe }
        actual_map.select { |k, v| k == :unsafe }.should be_eql expected_map.select { |k, v| k == :unsafe }

        results.should be_eql exp_results
    end
end
