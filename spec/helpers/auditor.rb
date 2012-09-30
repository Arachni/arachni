class Auditor
    include Arachni::Module::Auditor

    attr_accessor :page

    def self.info
        { name: 'Auditor' }
    end
end
