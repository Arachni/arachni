require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM, Element::Cookie::DOM,
          Element::LinkTemplate::DOM]
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
            expect(issue.page.dom.execution_flow_sinks).to be_any
            data_flow_sinks = issue.page.dom.data_flow_sinks

            if [Element::Link::DOM, Element::LinkTemplate::DOM].include? issue.vector.class
                expect(data_flow_sinks.size).to eq 2
            else
                expect(data_flow_sinks.size).to eq 1
            end

            data = data_flow_sinks.last
            expect(data.function.source).to start_with 'function pre_eval('
            expect(data.function.name).to eq 'pre_eval'
            expect(data.object).to eq 'DOMWindow'
            expect(data.taint).to include 'taint_tracer.log_execution_flow_sink()'
            expect(data.tainted_value).to include 'taint_tracer.log_execution_flow_sink()'
            expect(data.function.arguments).to eq [data.tainted_value]

            trace = data_flow_sinks.first.trace

            case issue.vector

                when Element::Form::DOM
                    expect(trace.size).to eq 2
                    expect(trace.first.function.source).to start_with 'function handleSubmit()'
                    expect(trace.first.function.name).to start_with 'handleSubmit'

                when Element::LinkTemplate::DOM
                    expect(trace.size).to eq 2
                    expect(trace.first.url).to eq issue.page.dom.url

                when Element::Link::DOM
                    expect(trace.size).to eq 2
                    expect(trace.first.url).to eq issue.page.dom.url

                when Element::Cookie::DOM
                    expect(trace.size).to eq 1
                    expect(trace.first.url).to eq issue.page.dom.url
            end

        end
    end
end
