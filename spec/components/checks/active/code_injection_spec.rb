require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(PHP Perl Python ASP)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_target
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
