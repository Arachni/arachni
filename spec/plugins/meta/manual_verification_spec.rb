require_relative '../../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        @issues = [Arachni::Issue.new( url: 'http://test.com/0', verification: true ),
                   Arachni::Issue.new( url: 'http://test.com/1', verification: false )]
        framework.modules.register_results( @issues )
    end

    def results
        issue = @issues.first
        {
            'hash'   => issue.digest,
            'index'  => 0,
            'url'    => issue.url,
            'name'   => issue.name,
            'var'    => issue.var,
            'elem'   => issue.elem,
            'method' => issue.method
        }
    end

    easy_test
end
