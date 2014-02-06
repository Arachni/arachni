require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:mysql, :mssql, :pgsql]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_platform
        {
            mysql: 16,
            pgsql: 6,
            mssql: 9
        }
    end

    easy_test
end
