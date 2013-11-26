require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::BODY, Element::HEADER ]
    end

    def issue_count
        2
    end

    easy_test( false ) do
        header_issue = issues.select { |i| i.elem == Element::HEADER }.first
        header_issue.var.should == 'Disclosure'
        header_issue.opts[:match].should == '192.168.1.121'

        body_issue   = issues.select { |i| i.elem == Element::BODY }.first
        body_issue.opts[:match].should == '192.168.1.12'
    end
end
