require_relative '../../spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Linux BSD Solaris Windows)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 4,
            Element::LINK   => 4,
            Element::COOKIE => 4,
            Element::HEADER => 3
        }
    end

    easy_test
end
