require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM, Element::Cookie::DOM,
          Element::UIForm::DOM ]
    end

    def issue_count_per_element
        {
            Element::Form::DOM   => 6,
            Element::Link::DOM   => 6,
            Element::Cookie::DOM => 6,
            Element::UIForm::DOM => 6
        }
    end

    easy_test
end
