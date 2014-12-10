shared_examples_for 'auditable' do |options = {}|
    it_should_behave_like 'inputtable', options
    it_should_behave_like 'submittable'
    it_should_behave_like 'mutable', options
    it_should_behave_like 'with_auditor'

    let(:opts) do
        {
            single_input:   false,
            supports_nulls: true
        }.merge( options )
    end

    before :each do
        @framework ||= Arachni::Framework.new
        @page      = Arachni::Page.from_url( url )
        @auditor   = Auditor.new( @page, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
        reset_options
    end

    let(:auditor) { @auditor }
    let(:seed) { 'my_seed' }

    let(:auditable) do
        if defined? super
            return super().tap { |s| s.auditor = auditor }
        else
            s = subject.dup
            s.auditor = auditor
            s.inputs = { subject.inputs.keys.first => subject.inputs.values.first }
            s
        end
    end

    let(:other) do
        new = auditable.dup
        new.inputs = { stuff: 'blah' }
        new
    end

    def has_parameter_extractor?
        begin
            auditable_extract_parameters
        rescue NoMethodError
            return false
        rescue
        end

        true
    end

    it "supports #{Arachni::RPC::Serializer}" do
        auditable.should == Arachni::RPC::Serializer.deep_clone( auditable )
    end

    describe '#to_rpc_data' do
        let(:data) { auditable.to_rpc_data }

        it 'excludes #audit_options' do
            data.should_not include 'audit_options'
        end
    end

    describe '#reset' do
        it 'clears #audit_options' do
            auditable.audit_options[:stuff] = true
            auditable.reset
            auditable.audit_options.should be_empty
        end
    end

    describe '#dup' do
        let(:dupped) { auditable.dup }

        it 'preserves #audit_options' do
            audited = nil
            dupped.audit( seed ) { |_, m| audited = m }
            run

            audited.audit_options.should be_any
            dupped = audited.dup
            dupped.audit_options.should == audited.audit_options

            dupped2 = dupped.dup
            dupped.audit_options.clear

            dupped2.audit_options.should == audited.audit_options
        end
    end

    describe '.skip_like' do
        it 'skips elements based on the block\'s return value' do
            audited = false
            auditable.audit( 'seed' ){ audited = true }
            run
            audited.should be_true

            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do
                true
            end

            audited = false
            auditable.audit( 'seed' ){ audited = true }
            run
            audited.should be_false
        end

        it 'skips element mutations based on the block\'s return value' do
            called = false
            auditable.audit( 'seed' ){ called = true }
            run
            called.should be_true

            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do |element|
                !!element.affected_input_name
            end

            i = 0
            auditable.audit( 'seed' ){ i += 1 }
            run
            i.should == 0
        end
    end

    describe '#audit_id' do
        let(:action) { "#{url}/action" }

        it 'takes into account the #auditor class' do
            auditable.auditor = 1
            id = auditable.audit_id

            auditable.auditor = '2'
            auditable.audit_id.should_not == id

            auditable.auditor = 1
            id = auditable.audit_id

            auditable.auditor = 2
            auditable.audit_id.should == id
        end

        it 'takes into account #action' do
            e = auditable.dup
            e.stub(:action) { action }

            c = auditable.dup
            c.stub(:action) { "#{action}2" }

            e.audit_id.should_not == c.audit_id
        end

        it 'takes into account #type' do
            e = auditable.dup
            e.stub(:type) { :blah }

            c = auditable.dup
            c.stub(:type) { :blooh }

            e.audit_id.should_not == c.audit_id
        end

        it 'takes into account #inputs names' do
            e = auditable.dup
            e.stub(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            c.stub(:inputs) { {input1: 'stuff2' } }
            e.audit_id.should == c.audit_id

            e = auditable.dup
            e.stub(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            c.stub(:inputs) { {input2: 'stuff' } }

            e.audit_id.should_not == c.audit_id
        end

        it 'takes into account the given payload' do
            id = auditable.audit_id( '1' )
            auditable.audit_id( '2' ).should_not == id
        end
    end

    describe '#coverage_id' do
        let(:action) { "#{url}/action" }

        it 'takes into account #action' do
            e = auditable.dup
            e.stub(:action) { action }

            c = auditable.dup
            c.stub(:action) { "#{action}2" }

            e.coverage_id.should_not == c.coverage_id
        end

        it 'takes into account #type' do
            e = auditable.dup
            e.stub(:type) { :blah }

            c = auditable.dup
            c.stub(:type) { :blooh }

            e.coverage_id.should_not == c.coverage_id
        end

        it 'takes into account #inputs names' do
            e = auditable.dup
            e.stub(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            c.stub(:inputs) { {input1: 'stuff2' } }
            e.coverage_id.should == c.coverage_id

            e = auditable.dup
            e.stub(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            c.stub(:inputs) { {input2: 'stuff' } }

            e.coverage_id.should_not == c.coverage_id
        end
    end

    describe '#coverage_hash' do
        it 'returns the String#persistent_hash of #coverage_id' do
            auditable.coverage_hash.should == auditable.coverage_id.persistent_hash
        end
    end

    describe '#audit' do
        context 'when no block is given' do
            it 'raises ArgumentError' do
                expect { auditable.audit( 'stuff' ) }.to raise_error ArgumentError
            end
        end

        context 'when the payloads is' do
            context String do
                it 'injects the given payload' do
                    payload = 'stuff-here'
                    injected = nil

                    auditable.audit( payload,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected = element.affected_input_value
                    end

                    run
                    injected.should == payload
                end

                context 'with invalid data' do
                    it 'is ignored' do
                        payload = 'stuff-here'
                        called  = 0

                        described_class.any_instance.stub(:valid_input_data?) { |i| i != payload }

                        auditable.audit( payload,
                                         format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                         skip_original: true
                        ) { |_, element| called += 1 }
                        run

                        called.should == 0
                    end
                end
            end
            context Array do
                it 'injects all supplied payload' do
                    payloads = [ 'stuff-here', 'stuff-here-2' ]
                    injected = []

                    auditable.audit( payloads,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected << element.affected_input_value
                    end

                    run
                    injected.uniq.sort.should == payloads.sort
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        auditable.audit( [],
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                          skip_original: true
                        ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_nil

                        run
                        injected.should be_empty
                    end
                end
            end

            context Hash do
                it 'picks payloads applicable to the resource\'s platforms' do
                    payloads = {
                        linux:   [ 'linux-payload-1', 'linux-payload-2' ],
                        php:     [ 'php-payload-1', 'php-payload-2' ],
                        apache:  'apache-payload',
                        windows: 'windows-payload',
                        aspx:    [ 'aspx-payload-1', 'aspx-payload-2' ]
                    }

                    injected = []

                    auditable.platforms.update %w(unix php apache)
                    auditable.audit( payloads,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected << element.affected_input_value
                    end.should be_true

                    run

                    payloads.delete( :windows )
                    payloads.delete( :aspx )

                    injected.uniq.sort.should == payloads.values.flatten.sort
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        auditable.audit( {},
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_nil

                        run
                        injected.should be_empty
                    end
                end

                context 'and the element has no identified platforms' do
                    it 'injects all given payloads' do
                        payloads = {
                            linux:   [ 'linux-payload-1', 'linux-payload-2' ],
                            bsd:     'freebsd-payload',
                            php:     [ 'php-payload-1', 'php-payload-2' ],
                            apache:  'apache-payload',
                            windows: 'windows-payload',
                            aspx:    [ 'aspx-payload-1', 'aspx-payload-2' ]
                        }

                        injected = []

                        auditable.platforms.clear
                        auditable.audit( payloads,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                          skip_original: true
                        ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_true

                        run

                        injected.uniq.sort.should == payloads.values.flatten.sort
                    end
                end

                context 'and there are no payloads for the resource\'s platforms' do
                    it 'returns nil' do
                        payloads = {
                            windows: 'windows-payload',
                            aspx:    [ 'aspx-payload-1', 'aspx-payload-2' ]
                        }

                        injected = []

                        auditable.platforms.update %w(unix php apache)
                        auditable.audit( payloads,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_nil

                        run

                        payloads.delete( :windows )
                        payloads.delete( :aspx )

                        injected.should be_empty
                    end
                end
            end

            describe 'other' do
                it 'raises ArgumentError' do
                    expect do
                        auditable.audit( :stuff,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end
                    end.to raise_error ArgumentError
                end
            end
        end

        context 'when called with option' do
            describe :submit do
                it 'uses them for the #submit call' do
                    options = { cookies: { stuff: 'blah' }}

                    called = false
                    each = proc do |mutation|
                        mutation.should receive(:submit).with(options)
                        called = true
                    end
                    auditable.audit( seed, each_mutation: each, submit: options ){}

                    called.should be_true
                end
            end

            describe :each_mutation do
                it 'is passed each generated mutation' do
                    pending if !has_parameter_extractor?

                    submitted = nil
                    cnt = 0

                    each_mutation = proc { |_| cnt += 1 }

                    auditable.audit( seed, each_mutation: each_mutation,
                                      skip_original: true,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                        submitted = auditable_extract_parameters( res )
                    end

                    run
                    cnt.should == 1
                    auditable.inputs == submitted
                end

                it 'is able to modify mutations on the fly' do
                    pending if !has_parameter_extractor?

                    submitted = nil

                    modified_seed = 'houa!'
                    each_mutation = proc do |mutation|
                        mutation.affected_input_value = modified_seed
                    end

                    auditable.audit( seed, each_mutation: each_mutation,
                                      skip_original: true,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                        submitted = auditable_extract_parameters( res )
                    end

                    run
                    submitted.values.first.should == modified_seed
                end

                context 'when it returns one or more elements of the same type' do
                    it 'audits those elements too' do
                        pending if !has_parameter_extractor?

                        injected = []
                        cnt = 0

                        each_mutation = proc do |mutation|
                            m = mutation.dup
                            m.affected_input_value = 'houa!'

                            c = mutation.dup
                            c.affected_input_value = 'houa2!'

                            [m, c]
                        end

                        auditable.audit( seed, each_mutation: each_mutation,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                            injected << auditable_extract_parameters( res ).values.first
                            cnt += 1
                        end

                        run
                        cnt.should == 3
                        injected.sort.should == [ seed, 'houa!', 'houa2!'].sort
                    end
                end
            end

            describe :skip_like do
                describe Proc do
                    it 'skips mutations based on the block\'s return value' do
                        audited   = []
                        skip_like = proc { |m| m.affected_input_name != auditable.inputs.keys.first }

                        auditable.audit( seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        run

                        audited.uniq!
                        audited.size.should == 1
                        audited.should == [auditable.inputs.keys.first]
                    end
                end

                describe Array do
                    it 'skips mutations based on the blocks\' return value' do
                        audited   = []
                        skip_like = []
                        skip_like << proc { |m| m.affected_input_name != auditable.inputs.keys.first }

                        auditable.audit( seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        run

                        audited.uniq!
                        audited.size.should == 1
                        audited.should      == [auditable.inputs.keys.first]
                    end
                end
            end

            describe :format do
                describe 'Arachni::Check::Auditor::Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        pending if !has_parameter_extractor?

                        injected = nil
                        cnt = 0

                        auditable.audit( seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end

                        run
                        cnt.should == 1
                        injected.should == seed
                    end
                end

                describe 'Arachni::Check::Auditor::Format::APPEND' do
                    it 'appends the seed to the existing value of the input' do
                        pending if !has_parameter_extractor?

                        injected = nil
                        cnt = 0

                        auditable.audit( seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::APPEND ] ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end

                        run
                        cnt.should == 1
                        injected.should == auditable.inputs.values.first + seed
                    end
                end

                describe 'Arachni::Check::Auditor::Format::NULL' do
                    it 'terminates the seed with a null character',
                       if: described_class != Arachni::Element::Header &&
                               described_class.is_a?( Arachni::Element::Capabilities::Auditable::DOM ) do
                        pending if !has_parameter_extractor?

                        injected = nil
                        cnt = 0
                        auditable.audit( seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::NULL ] ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end

                        run
                        cnt.should == 1
                        auditable.decode( injected ).should == seed + "\0"
                    end
                end

                describe 'Arachni::Check::Auditor::Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        pending if !has_parameter_extractor?

                        injected = nil
                        cnt = 0

                        format = [ Arachni::Check::Auditor::Format::SEMICOLON ]
                        auditable.audit( seed, skip_original: true, format: format ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end
                        run
                        cnt.should == 1

                        auditable.decode( injected ).should == ";" + seed
                    end
                end
            end

            describe :redundant do
                before do
                    @audit_opts = {
                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                        skip_original: true
                    }
                end

                context true do
                    it 'allows redundant audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.audit( seed, @audit_opts.merge( redundant: true )){ cnt += 1 }
                        end
                        run
                        cnt.should == 5
                    end
                end

                context false do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.audit( seed, @audit_opts.merge( redundant: false )){ cnt += 1 }
                        end
                        run
                        cnt.should == 1
                    end
                end

                context 'default' do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.audit( seed, @audit_opts ){ cnt += 1 }
                        end
                        run
                        cnt.should == 1
                    end
                end
            end
        end

        context "when the #{Arachni::OptionGroups::Audit}#exclude_vector_patterns option is set" do
            it 'skips those vectors by name' do
                Arachni::Options.audit.exclude_vector_patterns = auditable.inputs.keys

                audited = []
                auditable.audit( seed, skip_original: true ) do |_, elem|
                    audited << elem.affected_input_name
                end.should be_true

                run
                audited.should be_empty
            end
        end

        context "when #{Arachni::OptionGroups::Audit}#vector?" do
            context 'returns true' do
                it 'audits the input' do
                    Arachni::Options.audit.stub(:vector?){ true }

                    audited = []
                    auditable.audit( seed, skip_original: true ) do |_, elem|
                        audited << elem.affected_input_name
                    end.should be_true

                    run
                    audited.should_not be_empty
                end
            end

            context 'returns false' do
                it 'skips the input' do
                    Arachni::Options.audit.stub(:vector?){ false }

                    audited = []
                    auditable.audit( seed, skip_original: true ) do |_, elem|
                        audited << elem.affected_input_name
                    end.should be_true

                    run
                    audited.should be_empty
                end
            end
        end

        context "when #{described_class::Scope}#out?" do
            context true do
                it 'returns immediately' do
                    described_class::Scope.any_instance.stub(:out?) { true }

                    ran = false
                    auditable.audit( seed ) { ran = true }.should be_false
                    run
                    ran.should be_false
                end
            end
        end

        context 'when the element has no auditable inputs' do
            it 'returns immediately' do
                ran = false
                auditable.inputs = {}
                auditable.audit( seed ) { ran = true }.should be_false
                run

                ran.should be_false
            end
        end

        context 'when the auditor\'s #skip? method returns true for a mutation' do
            it 'is skipped' do
                ran = false
                auditable.audit( seed ) { ran = true }.should be_true
                run
                ran.should be_true

                Arachni::Element::Capabilities::Auditable.reset

                def auditor.skip?( elem )
                    true
                end

                ran = false
                auditable.audit( seed ) { ran = true }.should be_true
                run
                ran.should be_false

                Arachni::Element::Capabilities::Auditable.reset

                def auditor.skip?( elem )
                    false
                end

                ran = false
                auditable.audit( seed ) { ran = true }.should be_true
                run
                ran.should be_true
            end
        end

        context 'when the element\'s #skip? method returns true for a mutation' do
            it 'is skipped' do
                ran = false
                auditable.audit( seed ) { ran = true }.should be_true
                run
                ran.should be_true

                Arachni::Element::Capabilities::Auditable.reset

                def auditable.skip?( elem )
                    true
                end

                ran = false
                auditable.audit( seed ) { ran = true }.should be_true
                run
                ran.should be_false

                Arachni::Element::Capabilities::Auditable.reset

                def auditable.skip?( elem )
                    false
                end

                ran = false
                auditable.audit( seed ) { ran = true }.should be_true
                run
                ran.should be_true
            end
        end
    end
end
