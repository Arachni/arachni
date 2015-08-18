require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [Element::GenericDOM]
    end

    def issue_count_per_element
        {
            Element::GenericDOM => 10
        }
    end

    def find_issue( event )
        issues.find do |issue|
            "on#{issue.vector.method}" == event.to_s
        end
    end

    easy_test do
        issues.select { |i| i.vector.type == :input }.size.should == 9
        issues.select { |i| i.vector.type == :button }.size.should == 1

        Arachni::Browser::Javascript::EVENTS_PER_ELEMENT[:input].each do |event|
            find_issue( event ).vector.action.should end_with event.to_s
        end
    end
end
