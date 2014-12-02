require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:ruby, :php, :perl, :python, :jsp, :asp]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON ]
    end

    def issue_count_per_element
        {
            Element::Form         => 3,
            Element::Link         => 3,
            Element::Cookie       => 3,
            Element::Header       => 2,
            Element::LinkTemplate => 3,
            Element::JSON         => 3
        }
    end

    easy_test
end
