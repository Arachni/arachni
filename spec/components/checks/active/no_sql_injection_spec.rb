require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:mongodb]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON ]
    end

    def issue_count_per_element_per_platform
        {
            mongodb: {
                Element::Form         => 2,
                Element::Link         => 2,
                Element::Cookie       => 1,
                Element::Header       => 1,
                Element::LinkTemplate => 1,
                Element::JSON         => 2
            }
        }
    end

    easy_test
end
