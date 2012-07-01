require_relative '../../../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        issues = [Arachni::Issue.new( url: 'http://test.com/0', verification: true ),
                   Arachni::Issue.new( url: 'http://test.com/1', verification: false )]
        framework.modules.register_results( issues )
    end

    def results
        framework.auditstore.issues.map.with_index do |issue, idx|
            next if issue.url != 'http://test.com/0'
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
