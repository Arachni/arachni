require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:php, :perl, :python, :asp]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_platform
        {
            php:    8,
            perl:   8,
            python: 4,
            asp:    8,
            ruby:   8
        }
    end

    easy_test
end
