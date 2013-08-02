shared_examples_for "module" do
    include_examples 'component'

    module Format
        include Arachni::Element::Capabilities::Mutable::Format
    end

    module Element
        include Arachni::Element
    end

    module Severity
        include Arachni::Severity
    end

    before( :all ) do
        options.url = url
        framework.modules.load name

        # do not dedup, the module tests need to see everything
        current_module.instance_eval { define_method( :skip? ) { |elem| false } }

        @issues = []
        Arachni::Module::Manager.do_not_store
        Arachni::Module::Manager.on_register_results_raw do |issues|
            issues.each { |i| @issues << i }
        end
    end

    after( :each ) do
        Arachni::ElementFilter.reset
        Arachni::Element::Capabilities::Auditable.reset
        Arachni::Module::Manager.results.clear
        Arachni::Module::Manager.do_not_store

        # Leave this here, helps us save every kind of issue in order to test
        # the reports.
        if File.exists?( "#{Dir.tmpdir}/save_issues" )
            File.open( "#{Dir.tmpdir}/issues.yml", 'a' ){ |f| f.write @issues.to_yaml }
        end

        @issues.clear

        http.cookie_jar.clear

        framework.reset_spider
        framework.reset_filters
        framework.opts.dont_audit :links, :forms, :cookies, :headers
    end

    describe '.info' do
        it 'holds the right targets' do
            if current_module.info[:targets]
                current_module.info[:targets].sort.should == self.class.targets.sort
            else
                current_module.info[:targets].should == self.class.targets
            end
        end

        it 'holds the right elements' do
            if current_module.info[:elements]
                current_module.info[:elements].sort.should == self.class.elements.sort
            else
                current_module.info[:elements].should == self.class.elements
            end

        end
    end

    def self.easy_test( run_checks = true, &block )
        targets  = !self.targets || self.targets.empty? ? %w(Generic) : self.targets
        elements = !self.elements || self.elements.empty? ? %w(Generic) : self.elements

        context "when the target is" do
            targets.each do |target|
                context target do
                    before( :all ) do
                        if target.to_s.downcase != 'generic'
                            options.url = url + target.downcase
                            options.include = options.url
                        end
                    end

                    elements.each do |type|
                        it "logs vulnerable #{type}s" do
                            if !issue_count && !issue_count_per_target &&
                                !issue_count_per_element && !issue_count_per_element_per_target
                                raise 'No issue count provided via a suitable method.'
                            end

                            audit type.to_sym, run_checks

                            if issue_count
                                issues.size.should == issue_count
                            end

                            if issue_count_per_target
                                issues.size.should == issue_count_per_target[target.downcase.to_sym]
                            end

                            if issue_count_per_element
                                issues.size.should == issue_count_per_element[type]
                            end

                            if issue_count_per_element_per_target
                                issues.size.should == issue_count_per_element_per_target[target.downcase.to_sym][type]
                            end

                            instance_eval &block if block_given?
                        end
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

    def issue_count_per_element_per_target
    end

    def self.targets
    end

    def self.elements
    end

    def audit( element_type, logs_issues = true )
        options.audit element_type
        run

        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        e = element_type.to_s
        e = e[0...-1] if element_type.to_s[-1] == 's'

        if logs_issues && element_type.to_s.downcase != 'generic'
            # make sure we ONLY got results for the requested element type
            c = Arachni::Element.const_get( e.upcase.to_sym )
            issues.should be_any
            issues.map { |i| i.elem }.uniq.should == [c]

            if current_module.info[:issue]
                issues.map { |i| i.severity }.uniq.should ==
                    [current_module.info[:issue][:severity]]
            end
        end
    end

    def current_module
        framework.modules.values.first
    end

    def url
        @url ||= (web_server_url_for( "#{name}_module" ) rescue web_server_url_for( name ))  + '/'
    end

end
