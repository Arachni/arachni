require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM, Element::Cookie::DOM,
          Element::LinkTemplate::DOM ]
    end

    def issue_count_per_element
        {
            Element::Form::DOM         => 2,
            Element::Link::DOM         => 2,
            Element::Cookie::DOM       => 2,
            Element::LinkTemplate::DOM => 2
        }
    end

    easy_test do
        issues.each do |issue|
            transition      = issue.page.dom.transitions.last
            data_flow_sinks = issue.page.dom.data_flow_sinks

            case issue.vector

                when Element::Form::DOM
                    transition.element.tag_name.should == :form
                    transition.event.should == :submit

                    data_flow_sinks.should be_empty

                when Element::LinkTemplate::DOM
                    transition.element.should == :page
                    transition.event.should == :load

                    data_flow_sinks.size.should == 1
                    data_flow_sink = data_flow_sinks.first

                    data_flow_sink.function.source.should start_with 'function decodeURI()'
                    data_flow_sink.function.name.should == 'decodeURI'
                    data_flow_sink.object.should == 'DOMWindow'
                    data_flow_sink.tainted_value.should include Arachni::URI(issue.vector.seed).to_s
                    data_flow_sink.function.arguments.should == [data_flow_sink.tainted_value]

                when Element::Link::DOM
                    transition.element.should == :page
                    transition.event.should == :load

                    data_flow_sinks.size.should == 1
                    data_flow_sink = data_flow_sinks.first

                    data_flow_sink.function.source.should start_with 'function decodeURIComponent()'
                    data_flow_sink.function.name.should == 'decodeURIComponent'
                    data_flow_sink.object.should == 'DOMWindow'
                    data_flow_sink.tainted_value.should include Arachni::URI(issue.vector.seed).to_s
                    data_flow_sink.function.arguments.should == [data_flow_sink.tainted_value]

                when Element::Cookie::DOM
                    transition.element.should == :page
                    transition.event.should == :load
                    transition.options[:cookies].should == issue.vector.inputs
            end

        end
    end
end
