require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Unix Windows Tomcat PHP Perl)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_target
        {
            unix:    8,
            windows: 24,
            tomcat:  4,
            php:     36,
            perl:    36
        }
    end

    easy_test
end
