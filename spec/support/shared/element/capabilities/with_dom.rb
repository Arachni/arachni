shared_examples_for 'with_dom' do |html = nil|

    let(:with_dom) do
        dupped = subject.dup
        dupped.source = html if dupped.respond_to?( :source= )
        # It is lazy-loaded.
        dupped.dom
        dupped
    end

    describe '#skip_dom' do
        context 'when' do
            context true do
                before do
                    with_dom.skip_dom = true
                end

                it 'forces #dom to return nil' do
                    with_dom.dom.should be_nil
                end
            end

            context false do
                before do
                    with_dom.skip_dom = false
                end

                it 'forces #dom to return nil' do
                    with_dom.dom.should be_true
                end
            end
        end
    end

    describe '#skip_dom?' do
        context 'when #skip_dom is' do
            context true do
                before do
                    with_dom.skip_dom = true
                end

                it 'returns true' do
                    with_dom.skip_dom?.should be_true
                end
            end

            context false do
                before do
                    with_dom.skip_dom = false
                end

                it 'forces #dom to return nil' do
                    with_dom.skip_dom?.should be_false
                end
            end
        end
    end
    describe '#to_rpc_data' do
        let(:data) { with_dom.to_rpc_data }

        it "includes 'dom'" do
            data['dom'].should == with_dom.dom.to_rpc_data
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { with_dom.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( with_dom ) }

        it "restores 'dom'" do
            restored.dom.should == with_dom.dom
        end
    end

    describe '#dom' do
        it "returns #{described_class::DOM}" do
            with_dom.dom.should be_kind_of described_class::DOM
        end
    end

    describe '#dup' do
        let(:dupped) { with_dom.dup }

        it 'preserves #dom' do
            dupped.dom.should == with_dom.dom
        end
    end
end
