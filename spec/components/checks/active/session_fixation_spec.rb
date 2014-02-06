require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before :all do
        session.set_login_check( url, /dear user/ )
    end

    def self.elements
        [ Element::Form, Element::Link ]
    end

    def issue_count
        4
    end

    easy_test
end
