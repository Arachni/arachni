require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :bsd, :aix, :windows]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        h = {}
        [:unix, :bsd, :aix].each do |platform|
            h[platform] = {
                Element::Form         => 19,
                Element::Link         => 11,
                Element::Cookie       => 11,
                Element::Header       => 8,
                Element::LinkTemplate => 20,
                Element::JSON         => 11,
                Element::XML          => 22
            }
        end

        h[:windows] = {
            Element::Form         => 22,
            Element::Link         => 22,
            Element::Cookie       => 22,
            Element::Header       => 16,
            Element::LinkTemplate => 44,
            Element::JSON         => 22,
            Element::XML          => 44
        }

        h
    end

    easy_test
end
