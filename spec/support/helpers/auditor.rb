class Auditor
    include Arachni::Check::Auditor

    attr_accessor :page
    attr_accessor :framework

    def initialize( page = nil, framework = nil)
        @page      = page
        @framework = framework
    end

    def self.info
        { name: 'Auditor' }
    end
end
