shared_examples_for 'fingerprinter' do
    include_examples 'component'

    before :each do
        Arachni::Platforms.reset
    end

    def platforms_for( page )
        described_class.new( page ).run
        page.platforms
    end

end
