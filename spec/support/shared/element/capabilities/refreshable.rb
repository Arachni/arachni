shared_examples_for 'refreshable' do

    let( :refreshable ) { described_class }
    let( :url ) { @url + 'refreshable' }

    describe '#refresh' do

        context 'when the form disappears' do
            context 'when called without a block' do
                it 'returns nil' do
                    Arachni::HTTP.get( url + '_disappear_clear', async: false )

                    res = Arachni::HTTP.get( url + '_disappear', async: false ).response
                    refreshable.from_response( res ).select do |f|
                        !!f.auditable['nonce']
                    end.first.refresh.should be_nil
                end
            end

            context 'when called with a block' do
                it 'passes nil to the block' do
                    Arachni::HTTP.get( url + '_disappear_clear', async: false )

                    res = Arachni::HTTP.get( url + '_disappear', async: false ).response
                    refreshable.from_response( res ).select do |f|
                        !!f.auditable['nonce']
                    end.first.refresh do |r|
                        r.should be_nil
                    end
                end
            end
        end

        context 'when called without a block' do
            it 'refreshes the inputs of the form in blocking mode' do
                res = Arachni::HTTP.get( url, async: false ).response
                f   = refreshable.from_response( res ).select do |f|
                    !!f.auditable['nonce']
                end.first

                nonce = f.auditable['nonce'].dup

                updates = { 'new' => 'stuff', 'param_name' => 'other stuff' }
                f.update updates

                refreshed = f.refresh
                refreshed.auditable['nonce'].should_not == nonce
                refreshed.original['nonce'].should      == nonce

                updates['nonce'] = f.refresh.auditable['nonce']
                f.auditable.should == updates
            end
        end
        context 'when called with a block' do
            it 'refreshes the inputs of the form in async mode' do
                res = Arachni::HTTP.get( url, async: false ).response
                f   = refreshable.from_response( res ).select do |f|
                    !!f.auditable['nonce']
                end.first

                nonce = f.auditable['nonce'].dup

                updates = { 'new' => 'stuff', 'param_name' => 'other stuff' }
                f.update updates

                ran = false
                f.refresh do |form|
                    form.auditable['nonce'].should_not == nonce
                    form.original['nonce'].should      == nonce

                    updates['nonce'] = form.refresh.auditable['nonce']
                    form.auditable.should == updates

                    ran = true
                end

                Arachni::HTTP.run
                ran.should be_true
            end
        end
    end

end
