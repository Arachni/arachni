require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::SERVER ]
    end

    it 'intercepts all HTTP responses and log ones with status codes other than 200 or 404' do
        run
        current_module.acceptable.each do |code|
            http.get( url + code.to_s )
        end
        current_module.acceptable.each do |code|
            http.get( url + 'blah/' + code.to_s )
        end
        http.run

        max_issues = current_module.max_issues
        issues.size.should == max_issues
        issues.map{ |i| i.id.gsub( /\D/, '').to_i }.uniq.sort.should ==
            (current_module.acceptable - current_module::IGNORE_CODES.to_a).
                sort[0...max_issues]
    end
end
