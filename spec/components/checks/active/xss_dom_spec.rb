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
            transition     = issue.page.dom.transitions.last
            data_flow_sink = issue.page.dom.data_flow_sink

            case issue.vector

                when Element::Form::DOM
                    transition.element.tag_name.should == :form
                    transition.event.should == :submit

                    data_flow_sink.should be_empty

                when Element::LinkTemplate::DOM
                    transition.element.should == :page
                    transition.event.should == :load

                    data_flow_sink.size.should == 1
                    data_flow_sink = data_flow_sink.first

                    data = data_flow_sink[:data]
                    data.size.should == 1
                    data = data.first

                    data['source'].should start_with 'function decodeURI()'
                    data['function'].should == 'decodeURI'
                    data['object'].should == 'DOMWindow'
                    data['tainted'].should include Arachni::URI(issue.vector.seed).to_s
                    data['arguments'].should == [data['tainted']]

                when Element::Link::DOM
                    transition.element.should == :page
                    transition.event.should == :load

                    data_flow_sink.size.should == 1
                    data_flow_sink = data_flow_sink.first

                    data = data_flow_sink[:data]
                    data.size.should == 1
                    data = data.first

                    data['source'].should start_with 'function decodeURIComponent()'
                    data['function'].should == 'decodeURIComponent'
                    data['object'].should == 'DOMWindow'
                    data['tainted'].should include Arachni::URI(issue.vector.seed).to_s
                    data['arguments'].should == [data['tainted']]

                when Element::Cookie::DOM
                    transition.element.should == :page
                    transition.event.should == :load
                    transition.options[:cookies].should == [issue.vector]
            end

        end
    end
end
