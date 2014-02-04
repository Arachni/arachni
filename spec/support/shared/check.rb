shared_examples_for 'check' do
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
        @issues = []
        @url    = url
        @name   = name
    end

    before( :each ) do
        reset_framework
        options.url = @url

        framework.checks.load @name

        # Do not deduplicate, the check tests need to see everything.
        current_check.instance_eval { define_method( :skip? ) { |_| false } }

        Arachni::Check::Manager.do_not_store
        Arachni::Check::Manager.on_register_results_raw do |issues|
            issues.each { |i| @issues << i }
        end

        Arachni::Element::Capabilities::Auditable::Timeout.do_not_deduplicate
        Arachni::Check::Manager.do_not_store
    end

    after( :each ) do
        # Leave this here, helps us save every kind of issue in order to test
        # the reports.
        if File.exists?( "#{Dir.tmpdir}/save_issues" )

            File.open( "#{Dir.tmpdir}/issues.yaml", 'a' ) do |f|
                issues = []
                @issues.each do |issue|
                    issue.vector.remove_auditor
                    issue.vector.instance_eval { @page = nil if @page }

                    issue.request.instance_eval { @on_complete.clear } if issue.request
                    issue.request.performer = nil

                    issues << issue
                end

                f.write issues.to_yaml
            end
        end

        @issues.clear

        if ::EM.reactor_running?
            ::EM.stop
            sleep 0.1 while ::EM.reactor_running?
        end

        framework.reset
    end

    describe '.info' do
        it 'holds the right targets' do
            if current_check.info[:targets]
                current_check.info[:targets].sort.should == self.class.targets.sort
            else
                current_check.info[:targets].should == self.class.targets
            end
        end

        it 'holds the right elements' do
            current_check.info[:elements].map(&:to_s).sort.should ==
                self.class.elements.map(&:to_s).sort
        end
    end

    def self.easy_test( run_checks = true, &block )
        targets  = !self.targets  || self.targets.empty?  ? %w(Generic) : self.targets
        elements = !self.elements || self.elements.empty? ? %w(Generic) : self.elements

        context 'when the target is' do
            targets.each do |target|
                context target do

                    before( :each ) do
                        next if target.to_s.downcase == 'generic'

                        options.url = url + target.downcase
                        options.scope.include_path_patterns = options.url
                    end

                    elements.each do |type|
                        it "logs vulnerable #{type.type} elements" do
                            if !issue_count && !issue_count_per_target &&
                                !issue_count_per_element && !issue_count_per_element_per_target
                                raise 'No issue count provided via a suitable method.'
                            end

                            audit type, run_checks

                            if issue_count
                                issues.size.should == issue_count
                            end

                            if issue_count_per_target
                                issues.size.should ==
                                    issue_count_per_target[target.downcase.to_sym]
                            end

                            if issue_count_per_element
                                issues.size.should == issue_count_per_element[type]
                            end

                            if issue_count_per_element_per_target
                                issues.size.should ==
                                    issue_count_per_element_per_target[target.downcase.to_sym][type]
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
        if !element_type.is_a?( Symbol )
            element_type = element_type.type
        end

        options.audit.skip_elements :links, :forms, :cookies, :headers
        options.audit.elements element_type rescue NoMethodError
        run

        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        e = element_type.to_s
        e = e[0...-1] if element_type.to_s[-1] == 's'

        if logs_issues && element_type.to_s.downcase != 'generic'
            # make sure we ONLY got results for the requested element type
            issues.should be_any
            issues.map { |i| i.vector.type }.uniq.should == [e.to_sym]

            if current_check.info[:issue]
                issues.map { |i| i.severity }.uniq.should ==
                    [current_check.info[:issue][:severity]]
            end
        end
    end

    def current_check
        framework.checks.values.first
    end

    def url
        @url ||= (web_server_url_for( "#{name}_check" ) rescue web_server_url_for( name ))  + '/'
    end

end
