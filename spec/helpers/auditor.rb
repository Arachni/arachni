class Auditor
    include Arachni::Module::Auditor
    include Arachni::UI::Output

    attr_reader :http

    def initialize( http )
        @http = http
    end

    def self.info
        { name: 'Auditor' }
    end
end
