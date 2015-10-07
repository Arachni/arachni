shared_examples_for 'refreshable' do
    
    let( :refreshable ) { described_class }
    let( :refreshable_url ) { url + 'refreshable' }
    let(:http) { Arachni::HTTP::Client }

    describe '#refresh' do
        context 'when the form disappears' do
            context 'when called without a block' do
                it 'returns nil' do
                    http.get( refreshable_url + '_disappear_clear', mode: :sync )

                    response = http.get( refreshable_url + '_disappear', mode: :sync )
                    expect(refreshable.from_response( response ).select do |f|
                        !!f.inputs['nonce']
                    end.first.refresh).to be_nil
                end
            end

            context 'when called with a block' do
                it 'passes nil to the block' do
                    http.get( refreshable_url + '_disappear_clear', mode: :sync )

                    response = http.get( refreshable_url + '_disappear', mode: :sync )
                    refreshable.from_response( response ).select do |f|
                        !!f.inputs['nonce']
                    end.first.refresh do |r|
                        expect(r).to be_nil
                    end
                end
            end
        end

        context 'when called without a block' do
            it 'refreshes the inputs of the form in blocking mode' do
                res = http.get( refreshable_url, mode: :sync )
                f   = refreshable.from_response( res ).select do |f|
                    !!f.inputs['nonce']
                end.first

                nonce = f.inputs['nonce'].dup

                updates = { 'new' => 'stuff', 'param_name' => 'other stuff' }
                f.update updates

                refreshed = f.refresh
                expect(refreshed.inputs['nonce']).not_to     eq(nonce)
                expect(refreshed.default_inputs['nonce']).to eq(nonce)

                updates['nonce'] = f.refresh.inputs['nonce']
                expect(f.inputs).to eq(updates)
            end
        end
        context 'when called with a block' do
            it 'refreshes the inputs of the form in async mode' do
                res = http.get( refreshable_url, mode: :sync )
                f   = refreshable.from_response( res ).select do |f|
                    !!f.inputs['nonce']
                end.first

                nonce = f.inputs['nonce'].dup

                updates = { 'new' => 'stuff', 'param_name' => 'other stuff' }
                f.update updates

                ran = false
                f.refresh do |form|
                    expect(form.inputs['nonce']).not_to     eq(nonce)
                    expect(form.default_inputs['nonce']).to eq(nonce)

                    updates['nonce'] = form.refresh.inputs['nonce']
                    expect(form.inputs).to eq(updates)

                    ran = true
                end

                http.run
                expect(ran).to be_truthy
            end
        end
    end

end
