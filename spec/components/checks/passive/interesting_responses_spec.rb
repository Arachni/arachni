require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Server ]
    end

    it 'logs HTTP responses with status codes other than 200 or 404' do
        run
        current_check.acceptable.each do |code|
            http.get( url + code.to_s )
        end
        current_check.acceptable.each do |code|
            http.get( url + 'blah/' + code.to_s )
        end
        http.run

        max_issues = current_check.max_issues
        expect(issues.size).to eq(max_issues)
    end

    it 'skips HTTP responses which are out of scope' do
        options.scope.exclude_path_patterns << /blah/

        run

        current_check.acceptable.each do |code|
            http.get( url + 'blah/' + code.to_s )
        end
        http.run

        expect(issues).to be_empty
    end
end
