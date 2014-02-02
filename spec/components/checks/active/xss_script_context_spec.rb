require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count
        1
    end

    easy_test do
        issues.each do |i|
            i.trusted?.should be_false
            i.untrusted?.should be_true
            i.remarks[:check].should == [current_check::REMARK]
        end
    end
end
