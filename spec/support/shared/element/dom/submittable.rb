shared_examples_for 'submittable_dom' do
    it_should_behave_like 'submittable'

    describe '#submit' do
        it 'submits the element' do
            inputs = { subject.inputs.keys.first => subject.inputs.values.first + '1' }
            subject.inputs = inputs

            called = false
            subject.submit do |page|
                expect(inputs).to eq(auditable_extract_parameters( page ))
                called = true
            end

            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'sets the #performer on the returned page' do
            called = false
            subject.submit do |page|
                expect(page.performer).to be_kind_of described_class
                called = true
            end

            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'sets the #browser on the #performer' do
            called = false
            subject.submit do |page|
                expect(page.performer.browser).to be_kind_of Arachni::BrowserCluster::Worker
                called = true
            end

            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'adds the submission transitions to the Page::DOM#transitions' do
            transitions = []
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page
                transitions = subject.trigger
            end
            auditor.browser_cluster.wait

            submitted_page = nil
            subject.dup.submit do |page|
                submitted_page = page
            end
            auditor.browser_cluster.wait

            transitions.each do |transition|
                expect(subject.page.dom.transitions).not_to include transition
                expect(submitted_page.dom.transitions).to include transition
            end
        end

        context 'when the element could not be submitted' do
            it 'does not call the block' do
                allow_any_instance_of(subject.class).to receive( :trigger ) { [nil] }

                called = false
                subject.submit do
                    called = true
                end
                auditor.browser_cluster.wait
                expect(called).to be_falsey
            end
        end

        describe ':options' do
            describe ':custom_code' do
                it 'injects the given code' do
                    called = false
                    title = 'Injected title'

                    subject.submit custom_code: "document.title = #{title.inspect}" do |page|
                        expect(Nokogiri::HTML(page.body).css('title').text).to eq(title)
                        called = true
                    end

                    auditor.browser_cluster.wait
                    expect(called).to be_truthy
                end
            end

            describe ':taint' do
                it 'sets the Browser::Javascript#taint' do
                    taint = Arachni::Utilities.generate_token

                    set_taint = nil
                    subject.submit taint: taint do |page|
                        set_taint = page.performer.browser.javascript.taint
                    end

                    auditor.browser_cluster.wait
                    expect(set_taint).to eq(taint)
                end
            end
        end
    end
end
