shared_examples_for 'with_node' do
    before :each do
        @framework ||= Arachni::Framework.new
        @auditor   = Auditor.new( nil, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
        reset_options
    end

    let(:html) do
        '<form method="get" action="form_action" name="my_form">
            <input type=password name="my_first_input" value="my_first_value"" />
            <input type=radio name="my_second_input" value="my_second_value"" />
        </form>'
    end
    let(:with_node) do
        dupped = subject.dup
        dupped.html = html
        dupped
    end

    describe '#to_rpc_data' do
        let(:data) { with_node.to_rpc_data }

        it "includes 'html'" do
            data['html'].should == html
        end
    end

    describe '#node' do
        it 'returns the set node' do
            ap node = with_node.node
            ap with_node.html
            ap node.to_s
            node.is_a?( Nokogiri::XML::Element ).should be_true
            node.css( 'input' ).first['name'].should == 'my_first_input'
        end
    end

    describe '#dup' do
        let(:dupped) { with_node.dup }

        it 'preserves #html' do
            dupped.html.should == with_node.html
        end

        it 'preserves #node' do
            dupped.node.to_s.should == with_node.node.to_s
        end
    end
end
