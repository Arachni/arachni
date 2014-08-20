class Auditor < Arachni::Check::Base
    include Arachni::Check::Auditor

    attr_accessor :page
    attr_accessor :framework

    self.shortname = 'auditor_test'

    def initialize( page = nil, framework = nil)
        super
        http.update_cookies( page.cookie_jar ) if page
    end

    def self.info
        {
            name: 'Auditor',
            issue:       {
                name:            %q{Test issue},
                description:     %q{Test description},
                tags:            ['some', 'tag'],
                cwe:             '0',
                severity:        Issue::Severity::HIGH,
                remedy_guidance: %q{Watch out!.},
                remedy_code:     ''
            }
        }
    end
end
