def browser_cluster_job_taint_tracer_execution_flow_check_pages( pages )
    page = pages.find { |page| page.dom.execution_flow_sinks.any? }
    expect(page.dom.data_flow_sinks).to be_empty

    sink = page.dom.execution_flow_sinks
    expect(sink.size).to eq(1)

    trace = sink.first.trace
    expect(trace[0].function.source).to include 'log_execution_flow_sink()'
    expect(trace[1].function.source).to start_with 'function onsubmit'
end

def browser_cluster_job_taint_tracer_data_flow_check_pages( pages )
    page = pages.find { |page| page.dom.data_flow_sinks.any? }
    expect(page.dom.execution_flow_sinks).to be_empty

    sink = page.dom.data_flow_sinks

    expect(sink.first.function.name).to eq('process')
end

def browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages( pages )
    page = pages.find { |page| page.dom.data_flow_sinks.any? }
    expect(page.dom.execution_flow_sinks).to be_empty

    sink = page.dom.data_flow_sinks

    expect(sink.first.function.name).to eq('onClick')
end
