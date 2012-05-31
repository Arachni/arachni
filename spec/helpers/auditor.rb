class Auditor
    include Arachni::Module::Auditor

    def initialize( http )
        @http = http
    end

    def self.info
        { name: 'Auditor' }
    end
end
