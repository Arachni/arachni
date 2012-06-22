shared_examples_for "module" do

    module Format
        include Arachni::Parser::Element::Mutable::Format
    end

    module Element
        include Arachni::Issue::Element
    end

    module Severity
        include Arachni::Issue::Severity
    end

    before( :all ) do
        opts = Arachni::Options.instance.reset
        framework.modules.load name

        options.url = url

        http.headers['User-Agent'] = 'default'
    end

    after( :each ) do
        Arachni::Module::ElementDB.reset
        Arachni::Parser::Element::Auditable.reset
        Arachni::Module::Manager.results.clear

        http.cookie_jar.clear

        framework.opts.audit_links = false
        framework.opts.audit_forms = false
        framework.opts.audit_cookies = false
        framework.opts.audit_headers = false
    end

    after( :all ){ framework.modules.clear }

    describe '.info' do
        it 'should hold the right targets' do
            if component.info[:targets]
                component.info[:targets].sort.should == self.class.targets.sort
            else
                component.info[:targets].should == self.class.targets
            end
        end

        it 'should hold the right elements' do
            if component.info[:elements]
                component.info[:elements].sort.should == self.class.elements.sort
            else
                component.info[:elements].should == self.class.elements
            end
        end
    end

    def self.easy_test
        targets = !self.targets || self.targets.empty? ? %w(Generic) : self.targets

        targets.each do |target|
            context target do
                before( :all ) { options.url = url + target.downcase if target.to_s.downcase != 'generic' }

                elements.each do |type|
                    it "should audit #{type}" do
                        if !issue_count && !issue_count_per_target && !issue_count_per_element
                            raise 'No issue count provided via a suitable method.'
                        end

                        audit type.to_sym

                        if issue_count
                            issues.size.should == issue_count
                        end

                        if issue_count_per_target
                            issues.size.should == issue_count_per_target[target.downcase.to_sym]
                        end

                        if issue_count_per_element
                            issues.size.should == issue_count_per_element[type]
                        end

                    end
                end

            end
        end
    end

    def issue_count
    end

    def issue_count_per_target
    end

    def issue_count_per_element
    end

    def self.targets
    end

    def self.elements
    end

    def audit( element_type, logs_issues = true )
        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        options.send( "audit_#{e}=", true ) rescue
        run

        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        e = element_type.to_s
        e = e[0...-1] if element_type.to_s[-1] == 's'

        if logs_issues
            # make sure we ONLY got results for the requested element type
            c = Arachni::Issue::Element.const_get( e.upcase.to_sym )
            issues.should be_any
            issues.map { |i| i.elem }.uniq.should == [c]
        end
    end

    def name
        self.class.description
    end

    def url
        @url ||= (server_url_for( "#{name}_module" ) rescue server_url_for( name ))  + '/'
    end

    def framework
        @f ||= Arachni::Framework.new
    end

    def component
        framework.modules.values.first
    end

    def http
        framework.http
    end

    def options
        framework.opts
    end

    def run
        framework.run
    end
end
