shared_examples_for 'element_dom' do
    it_should_behave_like 'auditable', supports_nulls: false

    def run
        auditor.browser_cluster.wait
    end

    it 'supports .deep_clone' do
        called = false

        # We do this inside a #submit handler to make sure the associations
        # which are added during a submit are handled successfully.
        subject.submit do
            subject.deep_clone.should == subject
            called = true
        end
        run

        called.should be_true
    end

    describe '#url=' do
        it 'raises NotImplementedError' do
            expect { subject.url = url }.to raise_error NotImplementedError
        end
    end

    describe '#action=' do
        it 'raises NotImplementedError' do
            expect { subject.action = url }.to raise_error NotImplementedError
        end
    end

    describe '#prepare_for_report' do
        it 'removes #page' do
            subject.page.should be_true
            subject.prepare_for_report
            subject.page.should be_nil
        end
        it 'removes #parent' do
            subject.parent.should be_true
            subject.prepare_for_report
            subject.parent.should be_nil
        end
        it 'removes #browser' do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser

                subject.browser.should be_true
                subject.prepare_for_report
                subject.browser.should be_nil

                called = true
            end
            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

    describe '#with_browser_cluster' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserCluster to the given block' do
                    worker = nil

                    subject.with_browser_cluster do |cluster|
                        worker = cluster
                    end

                    worker.should == subject.auditor.browser_cluster
                end
            end
        end
    end

    describe '#with_browser' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserCluster::Worker to the given block' do
                    worker = nil

                    subject.with_browser do |browser|
                        worker = browser
                    end.should be_true
                    subject.auditor.browser_cluster.wait

                    worker.should be_kind_of Arachni::BrowserCluster::Worker
                end
            end
        end
    end

    describe '#submit' do
        it 'submits the element' do
            inputs = { 'param' => 'stuff' }
            subject.inputs = inputs

            called = false
            subject.submit do |page|
                inputs.should == auditable_extract_parameters( page )
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end

        it 'sets the #performer on the returned page' do
            called = false
            subject.submit do |page|
                page.performer.should be_kind_of described_class
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end

        it 'sets the #browser on the #performer' do
            called = false
            subject.submit do |page|
                page.performer.browser.should be_kind_of Arachni::BrowserCluster::Worker
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end

        it 'sets the #element on the #performer' do
            called = false
            subject.submit do |page|
                page.performer.element.should be_kind_of Watir::HTMLElement
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end

        it 'adds the submission transition to the Page::DOM#transitions' do
            transition = nil
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page
                transition = subject.trigger
            end
            subject.auditor.browser_cluster.wait

            submitted_page = nil
            subject.dup.submit do |page|
                submitted_page = page
            end
            subject.auditor.browser_cluster.wait

            subject.page.dom.transitions.should_not include transition
            submitted_page.dom.transitions.should include transition
        end

        context 'when the element could not be submitted' do
            it 'does not call the block' do
                subject.stub( :trigger ) { false }

                called = false
                subject.submit do
                    called = true
                end
                subject.auditor.browser_cluster.wait
                called.should be_false
            end
        end

        context 'when Browser#to_page returns nil' do
            it 'does not call the block' do
                Arachni::BrowserCluster::Worker.
                    any_instance.stub(:to_page).and_return(nil)

                called = false
                subject.submit do
                    called = true
                end
                subject.auditor.browser_cluster.wait
                called.should be_false
            end
        end

        describe :options do
            describe :custom_code do
                it 'injects the given code' do
                    called = false
                    title = 'Injected title'

                    subject.submit custom_code: "document.title = #{title.inspect}" do |page|
                        page.document.css('title').text.should == title
                        called = true
                    end

                    subject.auditor.browser_cluster.wait
                    called.should be_true
                end
            end

            describe :taint do
                it 'sets the Browser::Javascript#taint' do
                    taint = Arachni::Utilities.generate_token

                    set_taint = nil
                    subject.submit taint: taint do |page|
                        set_taint = page.performer.browser.javascript.taint
                    end

                    subject.auditor.browser_cluster.wait
                    set_taint.should == taint
                end
            end

        end
    end

    describe '#audit' do
        it 'submits all element mutations' do
            called = false
            subject.audit 'seed' do |page, element|
                element.inputs.should == auditable_extract_parameters( page )
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

    describe '#page' do
        it 'returns the page containing the element' do
            subject.page.should be_kind_of Arachni::Page
        end
    end

    describe '#node' do
        it 'returns the Nokogiri node of the element' do
            subject.node.is_a?( Nokogiri::XML::Element ).should be_true
        end
    end

    describe '#auditor' do
        it 'returns the assigned auditor' do
            subject.auditor.should be_kind_of Arachni::Check::Auditor
        end
    end

    describe '#dup' do
        it 'returns a copy' do
            dup = subject.dup
            dup.should == subject
        end

        it 'preserves the #parent' do
            subject.dup.parent.should == subject.parent
        end
    end

    describe '#to_hash' do
        it 'includes the #type' do
            subject.to_hash[:type].should == subject.type
        end

        it 'is aliased to #to_h' do
            subject.to_h.should == subject.to_hash
        end
    end
end
