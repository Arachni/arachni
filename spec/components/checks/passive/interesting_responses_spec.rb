require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Server ]
    end

    it 'intercepts all HTTP responses and log ones with status codes other than 200 or 404' do
        run
        current_check.acceptable.each do |code|
            http.get( url + code.to_s )
        end
        current_check.acceptable.each do |code|
            http.get( url + 'blah/' + code.to_s )
        end
        http.run

        max_issues = current_check.max_issues
        issues.size.should == max_issues
    end
end
