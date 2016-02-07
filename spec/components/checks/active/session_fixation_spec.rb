require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before :all do
        options.session.check_url     = url
        options.session.check_pattern = /dear user/
    end

    def self.elements
        [ Element::Form, Element::Link, Element::LinkTemplate ]
    end

    def issue_count
        8
    end

    easy_test
end
