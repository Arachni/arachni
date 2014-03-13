shared_examples_for 'element_dom' do
    it_should_behave_like 'auditable', supports_nulls: false

    def run
        auditor.browser_cluster.wait
    end

    describe '#url=' do
        it 'raises NotImplementedError'
    end

    describe '#action=' do
        it 'raises NotImplementedError'
    end

    it 'supports Marshal serialization'

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

        it 'adds the submission transition to the Page::DOM#transitions'

        context 'when the element could not be submitted' do
            it 'calls the block without arguments' do
                subject.stub( :trigger ) { false }
                subject.trigger

                page = false
                subject.submit do |p|
                    page = p
                end
                subject.auditor.browser_cluster.wait
                page.should be_nil
            end
        end

        context 'when Browser#to_page returns nil' do
            it 'does not call the block' do
                Arachni::BrowserCluster::Worker.any_instance.stub(:to_page).and_return(nil)

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

        it 'preserves the #parent'
    end
end
