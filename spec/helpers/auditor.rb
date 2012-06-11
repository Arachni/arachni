class Auditor
    include Arachni::Module::Auditor

    def self.info
        { name: 'Auditor' }
    end
end
