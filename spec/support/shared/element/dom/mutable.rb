shared_examples_for 'mutable_dom' do |options = {}|
    it_should_behave_like 'mutable', options.merge( supports_nulls: false )
end
