require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before :all do
        options.login.check_url     = url
        options.login.check_pattern = /dear user/
    end

    def self.elements
        [ Element::Form, Element::Link, Element::LinkTemplate ]
    end

    def issue_count
        4
    end

    easy_test
end
