shared_examples_for 'inputtable_dom' do |options = {}|
    it_should_behave_like 'inputtable', options

    it 'does not support null bytes'
end
