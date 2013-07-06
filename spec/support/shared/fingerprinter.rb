shared_examples_for 'fingerprinter' do
    include_examples 'component'

    before :each do
        Arachni::Platform::Manager.reset
    end

    def platforms_for( page )
        Arachni::Platform::Manager.reset
        described_class.new( page ).run
        page.platforms
    end

end
