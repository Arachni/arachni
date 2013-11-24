require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count
        1
    end

    easy_test do
        issues.each do |i|
            i.trusted?.should be_false
            i.untrusted?.should be_true
            i.requires_verification?.should be_true
            i.verification.should be_true
            i.remarks[:module].should == [current_module::REMARK]
        end
    end
end
