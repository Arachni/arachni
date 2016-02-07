require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:mongodb]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            mongodb: {
                Element::Form         => 2,
                Element::Link         => 2,
                Element::Cookie       => 2,
                Element::Header       => 1,
                Element::LinkTemplate => 2,
                Element::JSON         => 2,
                Element::XML          => 2
            }
        }
    end

    easy_test
end
