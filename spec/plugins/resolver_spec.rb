require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        issues = [Arachni::Issue.new( url: 'http://localhost' )]
        framework.modules.register_results( issues )
    end

    def results
        { 'localhost' => '127.0.0.1' }
    end

    easy_test
end
