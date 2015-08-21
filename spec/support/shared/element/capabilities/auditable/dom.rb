shared_examples_for 'element_dom' do |options = {}|
    it_should_behave_like 'element', options
    it_should_behave_like 'auditable', options.merge( supports_nulls: false )

    before :each do
        begin
            Arachni::Options.audit.elements described_class.type
        rescue Arachni::OptionGroups::Audit::Error
        end
    end

    def run
        auditor.browser_cluster.wait
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        %w(parent page browser element).each do |attribute|
            it "excludes #{attribute}" do
                called = false

                # We do this inside a #submit handler to make sure the associations
                # which are added during a submit are handled successfully.
                subject.submit do
                    expect(subject.to_rpc_data).not_to include attribute
                    called = true
                end
                run

                expect(called).to be_truthy
            end
        end
    end

    describe '#marshal_dump' do
        [:@parent, :@page, :@browser, :@element].each do |ivar|
            it "excludes #{ivar}" do
                called = false

                # We do this inside a #submit handler to make sure the associations
                # which are added during a submit are handled successfully.
                subject.submit do
                    expect(subject.marshal_dump).not_to include ivar
                    called = true
                end
                run

                expect(called).to be_truthy
            end
        end
    end

    describe '#prepare_for_report' do
        it 'removes #page' do
            expect(subject.page).to be_truthy
            subject.prepare_for_report
            expect(subject.page).to be_nil
        end
        it 'removes #parent' do
            expect(subject.parent).to be_truthy
            subject.prepare_for_report
            expect(subject.parent).to be_nil
        end
        it 'removes #browser' do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser

                expect(subject.browser).to be_truthy
                subject.prepare_for_report
                expect(subject.browser).to be_nil

                called = true
            end
            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
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

                    expect(worker).to eq(subject.auditor.browser_cluster)
                end
            end
        end
    end

    describe '#with_browser' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserCluster::Worker to the given block' do
                    worker = nil

                    expect(subject.with_browser do |browser|
                        worker = browser
                    end).to be_truthy
                    subject.auditor.browser_cluster.wait

                    expect(worker).to be_kind_of Arachni::BrowserCluster::Worker
                end
            end
        end
    end

    describe '#trigger' do
        it 'does not update the page transitions' do
            page = nil
            pre_transitions = nil
            subject.with_browser do |browser|
                browser.load subject.page
                subject.browser = browser
                pre_transitions = browser.transitions.dup

                subject.trigger
                page = browser.to_page
            end

            subject.auditor.browser_cluster.wait
            expect(page.dom.transitions).to eq(pre_transitions)
        end
    end

    describe '#submit' do
        it 'submits the element' do
            inputs = { subject.inputs.keys.first => subject.inputs.values.first + '1' }
            subject.inputs = inputs

            called = false
            subject.submit do |page|
                expect(inputs).to eq(auditable_extract_parameters( page ))
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'sets the #performer on the returned page' do
            called = false
            subject.submit do |page|
                expect(page.performer).to be_kind_of described_class
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'sets the #browser on the #performer' do
            called = false
            subject.submit do |page|
                expect(page.performer.browser).to be_kind_of Arachni::BrowserCluster::Worker
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'sets the #element on the #performer', if: !options[:without_node] do
            called = false
            subject.submit do |page|
                expect(page.performer.element).to be_kind_of Watir::HTMLElement
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'adds the submission transitions to the Page::DOM#transitions' do
            transitions = []
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page
                transitions = subject.trigger
            end
            subject.auditor.browser_cluster.wait

            submitted_page = nil
            subject.dup.submit do |page|
                submitted_page = page
            end
            subject.auditor.browser_cluster.wait

            transitions.each do |transition|
                expect(subject.page.dom.transitions).not_to include transition
                expect(submitted_page.dom.transitions).to include transition
            end
        end

        context 'when the element could not be submitted' do
            it 'does not call the block' do
                allow(subject).to receive( :trigger ) { false }

                called = false
                subject.submit do
                    called = true
                end
                subject.auditor.browser_cluster.wait
                expect(called).to be_falsey
            end
        end

        describe :options do
            describe :custom_code do
                it 'injects the given code' do
                    called = false
                    title = 'Injected title'

                    subject.submit custom_code: "document.title = #{title.inspect}" do |page|
                        expect(page.document.css('title').text).to eq(title)
                        called = true
                    end

                    subject.auditor.browser_cluster.wait
                    expect(called).to be_truthy
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
                    expect(set_taint).to eq(taint)
                end
            end
        end
    end

    describe '#audit' do
        it 'submits all element mutations' do
            called = false
            subject.audit 'seed' do |page, element|
                expect(auditable_extract_parameters( page )).to eq(element.inputs)
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end
    end

    describe '#valid_input_data?' do
        it 'returns true' do
            expect(subject.valid_input_data?( 'stuff' )).to be_truthy
        end

        described_class::INVALID_INPUT_DATA.each do |invalid_data|
            context "when the value contains #{invalid_data.inspect}" do
                it 'returns false' do
                    expect(subject.valid_input_data?( "stuff #{invalid_data}" )).to be_falsey
                end
            end
        end
    end

    describe '#page' do
        it 'returns the page containing the element' do
            expect(subject.page).to be_kind_of Arachni::Page
        end
    end

    describe '#node', if: !options[:without_node] do
        it 'returns the Nokogiri node of the element' do
            expect(subject.node.is_a?( Nokogiri::XML::Element )).to be_truthy
        end
    end

    describe '#auditor' do
        it 'returns the assigned auditor' do
            expect(subject.auditor).to be_kind_of Arachni::Check::Auditor
        end
    end

    describe '#encode' do
        it 'returns the string as is' do
            v = 'blah'
            expect(subject.encode( v ).object_id).to eq(v.object_id)
        end
    end
    describe '.encode' do
        it 'returns the string as is' do
            v = 'blah'
            expect(subject.class.encode( v ).object_id).to eq(v.object_id)
        end
    end

    describe '#decode' do
        it 'returns the string as is' do
            v = 'blah'
            expect(subject.decode( v ).object_id).to eq(v.object_id)
        end
    end
    describe '.decode' do
        it 'returns the string as is' do
            v = 'blah'
            expect(subject.class.decode( v ).object_id).to eq(v.object_id)
        end
    end

    describe '#dup' do
        it 'preserves the #parent' do
            expect(subject.dup.parent).to eq(subject.parent)
        end
    end
end
