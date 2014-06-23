require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM, Element::Cookie::DOM,
          Element::LinkTemplate::DOM]
    end

    def issue_count_per_element
        {
            Element::Form::DOM         => 3,
            Element::Link::DOM         => 3,
            Element::Cookie::DOM       => 2,
            Element::LinkTemplate::DOM => 3
        }
    end

    easy_test do
        issues.each do |issue|
            issue.page.dom.execution_flow_sinks.should be_any
            data_flow_sinks = issue.page.dom.data_flow_sinks

            if [Element::Link::DOM, Element::LinkTemplate::DOM].include? issue.vector.class
                data_flow_sinks.size.should == 2
            else
                data_flow_sinks.size.should == 1
            end

            data = data_flow_sinks.last[:data]
            data['source'].should start_with 'function eval()'
            data['function'].should == 'eval'
            data['object'].should == 'DOMWindow'
            data['taint'].should include 'taint_tracer.log_execution_flow_sink()'
            data['tainted'].should include 'taint_tracer.log_execution_flow_sink()'
            data['arguments'].should == [data['tainted']]

            trace = data_flow_sinks.first[:trace]

            case issue.vector

                when Element::Form::DOM
                    trace.size.should == 2
                    trace.first[:source].should start_with 'function handleSubmit()'
                    trace.first[:function].should start_with 'handleSubmit'

                when Element::LinkTemplate::DOM
                    trace.size.should == 2
                    trace.first[:url].should == issue.page.dom.url

                when Element::Link::DOM
                    trace.size.should == 2
                    trace.first[:url].should == issue.page.dom.url

                when Element::Cookie::DOM
                    trace.size.should == 1
                    trace.first[:url].should == issue.page.dom.url
            end

        end
    end
end
