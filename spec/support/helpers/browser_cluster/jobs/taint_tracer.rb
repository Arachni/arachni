def browser_cluster_job_taint_tracer_execution_flow_check_pages( pages )
    page = pages.find { |page| page.dom.execution_flow_sink.any? }
    page.dom.data_flow_sinks.should be_empty

    sink = page.dom.execution_flow_sink
    sink.size.should == 1

    trace = sink.first.trace
    trace.size.should == 2
    trace[0].function.source.should include 'log_execution_flow_sink()'
    trace[1].function.source.should start_with 'function onsubmit'
end

def browser_cluster_job_taint_tracer_data_flow_check_pages( pages )
    page = pages.find { |page| page.dom.data_flow_sinks.any? }
    page.dom.execution_flow_sink.should be_empty

    sink = page.dom.data_flow_sinks
    sink.size.should == 1

    sink.first.function.name.should == 'process'
end

def browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages( pages )
    page = pages.find { |page| page.dom.data_flow_sinks.any? }
    page.dom.execution_flow_sink.should be_empty

    sink = page.dom.data_flow_sinks
    sink.size.should == 1

    sink.first.function.name.should == 'onClick'
end
