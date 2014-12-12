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
                Element::Link         => 8,
                Element::Cookie       => 8,
                Element::Header       => 8,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 16
            },
            perl:    {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 8,
                Element::Header       => 8,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 16
            },
            python:  {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 8
            },
            asp:    {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 8,
                Element::Header       => 8,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 16
            },
            ruby:    {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 8,
                Element::Header       => 8,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 16
            }
        }
    end

    easy_test
end
