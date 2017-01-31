require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM, Element::Cookie::DOM,
          Element::LinkTemplate::DOM, Element::UIInput::DOM, Element::UIForm::DOM ]
    end

    def issue_count_per_element
        {
            Element::Form::DOM         => 2,
            Element::Link::DOM         => 2,
            Element::Cookie::DOM       => 2,
            Element::LinkTemplate::DOM => 2,
            Element::UIInput::DOM      => 2,
            Element::UIForm::DOM       => 2
        }
    end

    easy_test do
        issues.each do |issue|
            transition      = issue.page.dom.transitions.last
            data_flow_sinks = issue.page.dom.data_flow_sinks

            case issue.vector

                when Element::Form::DOM
                    expect(transition.element.tag_name).to eq :form
                    expect(transition.event).to eq :submit

                    expect(data_flow_sinks).to be_empty

                when Element::LinkTemplate::DOM
                    expect(transition.element).to eq :page
                    expect(transition.event).to eq :load

                    expect(data_flow_sinks.size).to eq 1
                    data_flow_sink = data_flow_sinks.first

                    expect(data_flow_sink.function.source).to start_with 'function decodeURI()'
                    expect(data_flow_sink.function.name).to eq 'decodeURI'
                    expect(data_flow_sink.object).to eq 'Window'
                    expect(data_flow_sink.tainted_value).to include Arachni::URI(issue.vector.seed).to_s
                    expect(data_flow_sink.function.arguments).to eq [data_flow_sink.tainted_value]

                when Element::Link::DOM
                    expect(transition.element).to eq :page
                    expect(transition.event).to eq :load

                    expect(data_flow_sinks.size).to eq 1
                    data_flow_sink = data_flow_sinks.first

                    expect(data_flow_sink.function.source).to start_with 'function decodeURIComponent()'
                    expect(data_flow_sink.function.name).to eq 'decodeURIComponent'
                    expect(data_flow_sink.object).to eq 'Window'
                    expect(data_flow_sink.tainted_value).to include Arachni::URI(issue.vector.seed).to_s
                    expect(data_flow_sink.function.arguments).to eq [data_flow_sink.tainted_value]

                when Element::Cookie::DOM
                    expect(transition.element).to eq :page
                    expect(transition.event).to eq :load
                    expect(transition.options[:cookies]).to eq issue.vector.inputs

                when Element::UIInput::DOM
                    expect(transition.element.tag_name).to eq :input
                    expect(transition.event).to eq :input

                    expect(data_flow_sinks).to be_empty

                when Element::UIForm::DOM
                    transitions = [
                        issue.page.dom.transitions.pop,
                        issue.page.dom.transitions.pop
                    ].reverse

                    expect(transitions[0].element.tag_name).to eq :input
                    expect(transitions[0].event).to eq :input

                    expect(transitions[1].element.tag_name).to eq :button
                    expect(transitions[1].event).to eq :click

                    expect(data_flow_sinks).to be_empty
            end

        end
    end
end
