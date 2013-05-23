require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(MySQL PostgreSQL MSSQL)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_target
        {
            mysql:      180,
            postgresql: 84,
            mssql:      27
        }
    end

    easy_test
end
