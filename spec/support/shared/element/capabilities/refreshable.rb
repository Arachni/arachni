shared_examples_for 'refreshable' do

    let( :refreshable ) { described_class }
    let( :url ) { @url + 'refreshable' }

    describe '#refresh' do

        context 'when the form disappears' do
            context 'when called without a block' do
                it 'returns nil' do
                    Arachni::HTTP::Client.get( url + '_disappear_clear', mode: :sync )

                    response = Arachni::HTTP::Client.get( url + '_disappear', mode: :sync )
                    refreshable.from_response( response ).select do |f|
                        !!f.inputs['nonce']
                    end.first.refresh.should be_nil
                end
            end

            context 'when called with a block' do
                it 'passes nil to the block' do
                    Arachni::HTTP::Client.get( url + '_disappear_clear', mode: :sync )

                    response = Arachni::HTTP::Client.get( url + '_disappear', mode: :sync )
                    refreshable.from_response( response ).select do |f|
                        !!f.inputs['nonce']
                    end.first.refresh do |r|
                        r.should be_nil
                    end
                end
            end
        end

        context 'when called without a block' do
            it 'refreshes the inputs of the form in blocking mode' do
                res = Arachni::HTTP::Client.get( url, mode: :sync )
                f   = refreshable.from_response( res ).select do |f|
                    !!f.inputs['nonce']
                end.first

                nonce = f.inputs['nonce'].dup

                updates = { 'new' => 'stuff', 'param_name' => 'other stuff' }
                f.update updates

                refreshed = f.refresh
                refreshed.inputs['nonce'].should_not == nonce
                refreshed.original['nonce'].should      == nonce

                updates['nonce'] = f.refresh.inputs['nonce']
                f.inputs.should == updates
            end
        end
        context 'when called with a block' do
            it 'refreshes the inputs of the form in async mode' do
                res = Arachni::HTTP::Client.get( url, mode: :sync )
                f   = refreshable.from_response( res ).select do |f|
                    !!f.inputs['nonce']
                end.first

                nonce = f.inputs['nonce'].dup

                updates = { 'new' => 'stuff', 'param_name' => 'other stuff' }
                f.update updates

                ran = false
                f.refresh do |form|
                    form.inputs['nonce'].should_not == nonce
                    form.original['nonce'].should      == nonce

                    updates['nonce'] = form.refresh.inputs['nonce']
                    form.inputs.should == updates

                    ran = true
                end

                Arachni::HTTP::Client.run
                ran.should be_true
            end
        end
    end

end
