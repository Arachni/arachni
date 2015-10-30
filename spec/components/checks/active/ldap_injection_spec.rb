require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        i = current_check.error_strings.size

        {
            Element::Form         => i,
            Element::Link         => i,
            Element::Cookie       => i,
            Element::Header       => i,
            Element::LinkTemplate => i * 2,
            Element::JSON         => i,
            Element::XML          => i * 2
        }
    end
    easy_test
end
