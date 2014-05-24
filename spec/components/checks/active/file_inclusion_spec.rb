require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :tomcat, :php, :perl]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 16,
                Element::Header       => 8,
                Element::LinkTemplate => 8
            },
            windows: {
                Element::Form         => 96,
                Element::Link         => 96,
                Element::Cookie       => 96,
                Element::Header       => 48,
                Element::LinkTemplate => 48
            },
            tomcat:  {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 4
            },
            php:  {
                Element::Form         => 120,
                Element::Link         => 120,
                Element::Cookie       => 120,
                Element::Header       => 60,
                Element::LinkTemplate => 60
            },
            perl:  {
                Element::Form         => 120,
                Element::Link         => 120,
                Element::Cookie       => 120,
                Element::Header       => 60,
                Element::LinkTemplate => 60
            }
        }
    end

    easy_test
end
