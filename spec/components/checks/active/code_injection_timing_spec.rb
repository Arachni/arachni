require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Java ASP Python PHP Perl Ruby)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element
        {
            Element::Form   => 3,
            Element::Link   => 3,
            Element::Cookie => 3,
            Element::Header => 2
        }
    end

    easy_test
end
