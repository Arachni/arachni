require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Body, Element::Header ]
    end

    def issue_count
        2
    end

    easy_test( false ) do
        header_issue = issues.select { |i| i.vector.class == Element::Header }.first
        expect(header_issue.vector.name).to eq 'Disclosure'
        expect(header_issue.proof).to eq '192.168.1.121'

        body_issue  = issues.select { |i| i.vector.class == Element::Body }.first
        expect(body_issue.proof).to eq '192.168.1.12'
    end
end
