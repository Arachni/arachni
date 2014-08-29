require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Cookie ]
    end

    def issue_count
        2
    end

    easy_test { issues.map { |i| i.vector.name }.sort.should == %w(cookie cookie2).sort }
end
