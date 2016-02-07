require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Body ]
    end

    def issue_count
        5
    end

    easy_test do
        emails = issues.map(&:proof).sort

        expect(emails).to eq [
            'tasos@example.com',
            'john@www.example.com',
            'john32.21d@example.com',
            'a.little.more.unusual@example.com',
            'a.little.more.unusual[at]example[dot]com'
        ].sort
    end
end
