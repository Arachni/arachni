require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:ruby, :php, :perl, :python, :java, :asp]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 4,
            Element::Link         => 4,
            Element::Cookie       => 4,
            Element::Header       => 3,
            Element::LinkTemplate => 4,
            Element::JSON         => 4,
            Element::XML          => 8
        }
    end

    easy_test
end
