shared_examples_for 'refreshable' do

    let( :refreshable ) { described_class }
    let( :url ) { @url + 'refreshable' }

    describe '#refresh' do
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
