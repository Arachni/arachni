shared_examples_for 'with_auditor' do
    before :each do
        @framework ||= Arachni::Framework.new
        @auditor   = Auditor.new( nil, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
        reset_options
    end

    let(:auditor) { @auditor }
    let(:orphan) { subject.dup.tap { |s| s.auditor = nil } }
    let(:auditable) do
        s = subject.dup
        s.auditor = auditor
        s
    end

    describe '#to_rpc_data' do
        let(:data) { auditable.to_rpc_data }

        it "does not include 'auditor'" do
            data.should_not include 'auditor'
        end
    end

    describe '#prepare_for_report' do
        it 'removes the #auditor' do
            auditable.auditor.should be_true
            auditable.prepare_for_report
            auditable.auditor.should be_nil
        end
    end

    describe '#marshal_dump' do
        it 'excludes @auditor' do
            auditable.marshal_dump.should_not include :@auditor
        end
    end

    describe '#remove_auditor' do
        it 'removes the auditor' do
            auditable.auditor = :some_auditor
            auditable.auditor.should == :some_auditor
            auditable.remove_auditor
            auditable.auditor.should be_nil
        end
    end

    describe '#orphan?' do
        context 'when it has no auditor' do
            it 'returns true' do
                orphan.orphan?.should be_true
            end
        end
        context 'when it has an auditor' do
            it 'returns true' do
                auditable.orphan?.should be_false
            end
        end
    end

    describe '#dup' do
        let(:dupped) { auditable.dup }

        it 'preserves the #auditor' do
            dupped.auditor.should == auditable.auditor

            subject.remove_auditor
            dup.auditor.should be_true
        end
    end
end
