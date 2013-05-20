shared_examples_for 'fingerprinter' do
    include_examples 'component'

    before :each do
        Arachni::Platforms.reset
    end

    def platforms_for( page )
        Arachni::Platforms.reset
        described_class.new( page ).run
        page.platforms
    end

end
