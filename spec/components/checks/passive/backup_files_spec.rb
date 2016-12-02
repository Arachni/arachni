require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Server ]
    end

    def issue_count
        current_check.formats.size
    end

    easy_test do
        expect(issues.find { |issue| issue.remarks.empty? }).to be_nil
        expect(issues.find { |issue| current_check::IGNORE_EXTENSIONS.include?( issue.response.parsed_url.resource_extension) }).to be_nil

        current_check::IGNORE_EXTENSIONS.each do |extension|
            expect(framework.sitemap.find { |url, _| url.end_with?( ".#{extension}" ) }).to be_truthy
        end
    end
end
