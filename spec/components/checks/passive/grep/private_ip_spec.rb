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
        header_issue.vector.name.should == 'Disclosure'
        header_issue.proof.should == '192.168.1.121'

        body_issue  = issues.select { |i| i.vector.class == Element::Body }.first
        body_issue.proof.should == '192.168.1.12'
    end
end
