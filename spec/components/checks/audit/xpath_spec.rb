require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(General PHP Java dotNET libXML2)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_target
        {
            general: 39,
            php:     6,
            java:    9,
            dotnet:  15,
            libxml2: 6
        }
    end

    easy_test
end
