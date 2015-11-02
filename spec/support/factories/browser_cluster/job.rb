Factory.define :custom_job do
    class CustomJob < Arachni::BrowserCluster::Job
        class Result < Arachni::BrowserCluster::Job::Result
            attr_accessor :my_data
        end

        def run
            sleep 0.1
            save_result my_data: 'Some stuff'
        end
    end

    CustomJob.new
end

Factory.define :sleep_job do
    class CustomJob < Arachni::BrowserCluster::Job
        class Result < Arachni::BrowserCluster::Job::Result
            attr_accessor :my_data
        end

        def run
            loop { sleep 1 }
        end
    end

    CustomJob.new
end
