class Auditor < Arachni::Component::Base
    include Arachni::Check::Auditor

    attr_accessor :page
    attr_accessor :framework

    self.shortname = 'auditor_test'

    def initialize( page = nil, framework = nil)
        @page      = page
        @framework = framework

        http.update_cookies( page.cookiejar ) if page
    end

    def self.info
        { name: 'Auditor' }
    end
end
