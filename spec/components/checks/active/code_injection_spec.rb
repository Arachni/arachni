require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:php, :perl, :python, :asp]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            php:    {
                Element::Form         => 8,
                Element::Link         => 4,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 4,
                Element::XML          => 8
            },
            perl:    {
                Element::Form         => 8,
                Element::Link         => 4,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 4,
                Element::XML          => 8
            },
            python:  {
                Element::Form         => 4,
                Element::Link         => 2,
                Element::Cookie       => 2,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 2,
                Element::XML          => 4
            },
            asp:    {
                Element::Form         => 8,
                Element::Link         => 5,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 4,
                Element::XML          => 8
            },
            ruby:    {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 8
            }
        }
    end

    easy_test
end
