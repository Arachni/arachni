def issues
    Arachni::Module::Manager.results
end

def run_http!
    Arachni::HTTP.instance.run
end
