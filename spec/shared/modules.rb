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

        # do not dedup, the module tests need to see everything
        current_module.instance_eval do
            define_method( :skip? ) do |elem|
                return false
            end
        end

        options.url = url

        http.headers['User-Agent'] = 'default'

        @issues = []
        Arachni::Module::Manager.on_register_results_raw do |issues|
            issues.each { |i| @issues << i }
        end
    end

    after( :each ) do
        Arachni::Module::ElementDB.reset
        Arachni::Parser::Element::Auditable.reset
        Arachni::Module::Manager.results.clear
        Arachni::Module::Manager.do_not_store

        @issues.clear

        http.cookie_jar.clear

        framework.opts.audit_links = false
        framework.opts.audit_forms = false
        framework.opts.audit_cookies = false
        framework.opts.audit_headers = false
    end

    after( :all ){ framework.modules.clear }

    describe '.info' do
        it 'should hold the right targets' do
            if current_module.info[:targets]
                current_module.info[:targets].sort.should == self.class.targets.sort
            else
                current_module.info[:targets].should == self.class.targets
            end
        end

        it 'should hold the right elements' do
            if current_module.info[:elements]
                current_module.info[:elements].sort.should == self.class.elements.sort
            else
                current_module.info[:elements].should == self.class.elements
            end
        end
    end

    def self.use_https
        before( :all ) { options.url.gsub!( 'http', 'https' ) }
    end

    def self.easy_test( &block )
        targets  = !self.targets || self.targets.empty? ? %w(Generic) : self.targets
        elements = !self.elements || self.elements.empty? ? %w(Generic) : self.elements

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

                        instance_eval &block if block_given?
                    end
                end

            end
        end
    end

    def issues
        @issues
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

        begin
            options.send( "audit_#{e}=", true )
        rescue
        end
        run

        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        e = element_type.to_s
        e = e[0...-1] if element_type.to_s[-1] == 's'

        if logs_issues && element_type.to_s.downcase != 'generic'
            # make sure we ONLY got results for the requested element type
            c = Arachni::Issue::Element.const_get( e.upcase.to_sym )
            issues.should be_any
            issues.map { |i| i.elem }.uniq.should == [c]

            if current_module.info[:issue]
                issues.map { |i| i.severity }.uniq.should ==
                    [current_module.info[:issue][:severity]]
            end
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

    def current_module
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
