def issues
    Arachni::Module::Manager.results
end

def spec_path
    @@root
end

def run_http!
    Arachni::HTTP.instance.run
end
