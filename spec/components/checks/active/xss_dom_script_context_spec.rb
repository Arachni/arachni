require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM ]
    end

    def issue_count_per_element
        {
            Element::Form::DOM => 3,
            Element::Link::DOM => 3
        }
    end

    easy_test do
        issues.each do |issue|
            issue.page.dom.execution_flow_sink.should be_any
            data_flow_sink = issue.page.dom.data_flow_sink

            data_flow_sink.size.should == 1

            data = data_flow_sink.first[:data]
            data.size.should == 1
            data = data.first
            data['source'].should start_with 'function eval()'
            data['function'].should == 'eval'
            data['object'].should == 'DOMWindow'
            data['taint'].should include 'taint_tracer.log_execution_flow_sink()'
            data['tainted'].should include 'taint_tracer.log_execution_flow_sink()'
            data['arguments'].should == [data['tainted']]

            trace = data_flow_sink.first[:trace]

            if issue.vector.is_a? Element::Form::DOM
                trace.size.should == 2
                trace.first[:source].should start_with 'function handleSubmit()'
                trace.first[:function].should start_with 'handleSubmit'
            else
                trace.size.should == 1
                trace.first[:url].should == issue.page.dom.url
            end

        end
    end
end
