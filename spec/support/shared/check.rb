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

        options.audit.parameter_names      = true
        options.audit.with_extra_parameter = true

        framework.checks.load @name

        # Do not deduplicate, the check tests need to see everything.
        current_check.instance_eval { define_method( :skip? ) { |_| false } }

        Arachni::Data.issues.do_not_store
        Arachni::Data.issues.on_new_pre_deduplication do |issue|
            @issues << issue

            # Leave this here, helps us save every kind of issue in order to test
            # the reporters.
            if $spec_issues
                $spec_issues << issue
            end
        end

        Arachni::Element::Capabilities::Analyzable::Timeout.do_not_deduplicate
    end

    after( :each ) do
        @issues.clear
        process_kill_reactor
        framework.reset
    end

    describe '.info' do
        it 'holds the right platforms' do
            current_check.platforms.sort.should == self.class.platforms.sort
        end

        it 'holds the right elements' do
            current_check.info[:elements].map(&:to_s).sort.should ==
                self.class.elements.map(&:to_s).sort
        end
    end

    def self.easy_test( run_checks = true, &block )
        if self.platforms.any?
            context 'when the platform is' do
                platforms.each do |platform|
                    test_platform( platform, run_checks, &block )
                end
            end
        else
            elements.each do |element|
                test_element( element, nil, run_checks, &block )
            end
        end
    end

    def self.test_platform( platform, run_checks, &block )
        context platform do
            elements.each do |element|
                test_element( element, platform, run_checks, &block )
            end
        end
    end

    def self.test_element( element, platform, run_checks, &block )
        it "logs vulnerable #{element.type} elements" do
            run_test element, platform, run_checks, &block
        end
    end

    def run_test( element, platform, run_checks, &block )
        if !issue_count && !issue_count_per_platform &&
            !issue_count_per_element && !issue_count_per_element_per_platform
            raise 'No issue count provided via a suitable method.'
        end

        options.url = url + platform.to_s
        options.scope.include_path_patterns = options.url

        audit element, run_checks

        if issue_count
            issues.size.should == issue_count
        end

        if issue_count_per_platform
            issues.size.should ==
                issue_count_per_platform[platform]
        end

        if issue_count_per_element
            issues.size.should == issue_count_per_element[element]
        end

        if issue_count_per_element_per_platform
            issues.size.should ==
                issue_count_per_element_per_platform[platform][element]
        end

        instance_eval &block if block_given?
    end

    def issues
        @issues
    end

    def issue_count
    end

    def issue_count_per_platform
    end

    def issue_count_per_element
    end

    def issue_count_per_element_per_platform
    end

    def self.platforms
        []
    end

    def self.elements
    end

    def audit( element_type, logs_issues = true )
        if !element_type.is_a?( Symbol )
            element_type = element_type.type
        end

        self.class.elements.map(&:type).each do |type|
            options.audit.skip_elements type rescue NoMethodError
        end

        if element_type.to_s.start_with? 'link_template'
            options.audit.link_templates = [
                /\/input\/(?<input>.+)\//,
                /input\|(?<input>.+)/
            ]
        else
            options.audit.elements element_type rescue NoMethodError
        end

        run

        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        e = element_type.to_s
        e = e[0...-1] if element_type.to_s[-1] == 's'

        if logs_issues && issues.any?
            # make sure we ONLY got results for the requested element type
            issues.map { |i| i.vector.class.type }.uniq.should == [e.to_sym]

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
        @url ||= (
                begin
                    web_server_url_for( "#{name}_check" )
                rescue
                    begin
                        web_server_url_for( name )
                    rescue
                        web_server_url_for( "#{name}_https" )
                    end
                end
        )  + '/'
    end

end
