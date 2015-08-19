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
            expect(data).not_to include 'auditor'
        end
    end

    describe '#prepare_for_report' do
        it 'removes the #auditor' do
            expect(auditable.auditor).to be_truthy
            auditable.prepare_for_report
            expect(auditable.auditor).to be_nil
        end
    end

    describe '#marshal_dump' do
        it 'excludes @auditor' do
            expect(auditable.marshal_dump).not_to include :@auditor
        end
    end

    describe '#remove_auditor' do
        it 'removes the auditor' do
            auditable.auditor = :some_auditor
            expect(auditable.auditor).to eq(:some_auditor)
            auditable.remove_auditor
            expect(auditable.auditor).to be_nil
        end
    end

    describe '#orphan?' do
        context 'when it has no auditor' do
            it 'returns true' do
                expect(orphan.orphan?).to be_truthy
            end
        end
        context 'when it has an auditor' do
            it 'returns true' do
                expect(auditable.orphan?).to be_falsey
            end
        end
    end

    describe '#dup' do
        let(:dupped) { auditable.dup }

        it 'preserves the #auditor' do
            expect(dupped.auditor).to eq(auditable.auditor)

            subject.remove_auditor
            expect(dup.auditor).to be_truthy
        end
    end
end
