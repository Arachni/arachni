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
            mysql:      60,
            postgresql: 28,
            mssql:      9
        }
    end

    easy_test
end
