shared_examples_for 'element_dom' do
    it_should_behave_like 'element'

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
