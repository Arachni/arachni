require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :bsd, :aix, :windows]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON ]
    end

    def issue_count_per_element_per_platform
        h = {}
        [:unix, :bsd, :aix].each do |platform|
            h[platform] = {
                Element::Form         => 22,
                Element::Link         => 22,
                Element::Cookie       => 22,
                Element::Header       => 19,
                Element::LinkTemplate => 21,
                Element::JSON         => 22
            }
        end

        h[:windows] = {
            Element::Form         => 44,
            Element::Link         => 44,
            Element::Cookie       => 44,
            Element::Header       => 38,
            Element::LinkTemplate => 44,
            Element::JSON         => 44
        }

        h
    end

    easy_test
end
