require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Java ASP Python PHP Perl Ruby)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 3,
            Element::LINK   => 3,
            Element::COOKIE => 3,
            Element::HEADER => 2
        }
    end

    easy_test
end
