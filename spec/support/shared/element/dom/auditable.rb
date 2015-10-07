shared_examples_for 'auditable_dom' do
    it_should_behave_like 'auditable'

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

    describe '#auditor' do
        it 'returns the assigned auditor' do
            expect(subject.auditor).to be_kind_of Arachni::Check::Auditor
        end
    end
end
