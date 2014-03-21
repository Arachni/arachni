shared_examples_for 'option_group' do
    it { should respond_to :to_h }

    described_class.defaults.each do |k, v|
        describe "##{k}" do
            it "defaults to #{v}" do
                subject.instance_variable_get( "@#{k}".to_sym ).should == v
                subject.send( k ).should == v
            end
        end
    end

    it 'honors default values for attributes' do
        subject.defaults.each do |k, v|
            subject.send "#{k}=", nil
            subject.instance_variable_get( "@#{k}".to_sym ).should == v
            subject.send( k ).should == v
        end
    end

    describe '#to_hash' do
        it 'returns a hash' do
            subject.to_hash.should be_kind_of Hash
        end
    end

    describe '#to_h' do
        it 'returns a hash' do
            subject.to_h.should be_kind_of Hash
        end

        it 'only includes attributes with accessors' do
            method = subject.methods.find { |m| m.to_s.end_with? '=' }
            if method == :=== || method == :==
                subject.to_h.should be_empty
                next
            end

            subject.send( method, 'stuff' )

            hash = subject.to_h
            hash.should be_any
            hash.each do |k, v|
                subject.should respond_to "#{k}="
            end
        end
    end

    describe '#update' do
        it 'updates self with the values of the given hash' do
            method = subject.methods.find { |m| m.to_s.end_with? '=' }
            next if method == :=== || method == :==

            method = method.to_s[0...-1].to_sym
            value  = 'stuff'

            subject.update( { method => value } )
            subject.send( method ).should include value
        end

        it 'returns self' do
            subject.update({}).should == subject
        end
    end

    describe '#merge' do
        it 'updates self with the values of the given OptionGroup' do
            method = subject.methods.find { |m| m.to_s.end_with? '=' }
            next if method == :=== || method == :==

            method = method.to_s[0...-1].to_sym
            value  = 'stuff'

            group = described_class.new
            group.update( { method => value } )

            subject.merge( group )
            subject.send( method ).should include value
        end

        it 'returns self' do
            group = described_class.new
            subject.merge( group ).should == subject
        end
    end
end
