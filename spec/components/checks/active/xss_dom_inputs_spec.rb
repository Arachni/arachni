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
        expect(issues.select { |i| i.vector.type == :input }.size).to eq 9
        expect(issues.select { |i| i.vector.type == :button }.size).to eq 1

        Arachni::Browser::Javascript::EVENTS_PER_ELEMENT[:input].each do |event|
            expect(find_issue( event ).vector.action).to end_with event.to_s
        end
    end
end
