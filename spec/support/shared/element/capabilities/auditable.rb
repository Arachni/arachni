shared_examples_for 'auditable' do

    before :each do
        begin
            Arachni::Options.audit.elements described_class.type
        rescue Arachni::OptionGroups::Audit::Error => e
        end
    end

    after :each do
        reset_options
    end

    let(:seed) { 'my_seed' }

    let(:auditable) do
        if defined? super
            super().tap { |s| s.auditor = auditor }
        else
            s = subject.dup
            s.auditor = auditor
            s.inputs = { subject.inputs.keys.first => '1' }
            s
        end
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
        expect(auditable).to eq(Arachni::RPC::Serializer.deep_clone( auditable ))
    end

    describe '#to_rpc_data' do
        let(:data) { auditable.to_rpc_data }

        it 'excludes #audit_options' do
            expect(data).not_to include 'audit_options'
        end
    end

    describe '#reset' do
        it 'clears #audit_options' do
            auditable.audit_options[:stuff] = true
            auditable.reset
            expect(auditable.audit_options).to be_empty
        end
    end

    describe '#dup' do
        let(:dupped) { auditable.dup }

        it 'preserves #audit_options' do
            audited = nil
            dupped.audit( seed ) { |_, m| audited = m }
            run

            expect(audited.audit_options).to be_any
            dupped = audited.dup
            expect(dupped.audit_options).to eq(audited.audit_options)

            dupped2 = dupped.dup
            dupped.audit_options.clear

            expect(dupped2.audit_options).to eq(audited.audit_options)
        end
    end

    describe '.skip_like' do
        it 'skips elements based on the block\'s return value' do
            audited = false
            auditable.audit( 'seed' ){ audited = true }
            run
            expect(audited).to be_truthy

            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do
                true
            end

            audited = false
            auditable.audit( 'seed' ){ audited = true }
            run
            expect(audited).to be_falsey
        end

        it 'skips element mutations based on the block\'s return value' do
            called = false
            auditable.audit( 'seed' ){ called = true }
            run
            expect(called).to be_truthy

            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do |element|
                !!element.affected_input_name
            end

            i = 0
            auditable.audit( 'seed' ){ i += 1 }
            run
            expect(i).to eq(0)
        end
    end

    describe '#audit_id' do
        let(:action) { "#{url}/action" }

        it 'takes into account the #auditor class' do
            auditable.auditor = 1
            id = auditable.audit_id

            auditable.auditor = '2'
            expect(auditable.audit_id).not_to eq(id)

            auditable.auditor = 1
            id = auditable.audit_id

            auditable.auditor = 2
            expect(auditable.audit_id).to eq(id)
        end

        it 'takes into account #action' do
            e = auditable.dup
            allow(e).to receive(:action) { action }

            c = auditable.dup
            allow(c).to receive(:action) { "#{action}2" }

            expect(e.audit_id).not_to eq(c.audit_id)
        end

        it 'takes into account #type' do
            e = auditable.dup
            allow(e).to receive(:type) { :blah }

            c = auditable.dup
            allow(c).to receive(:type) { :blooh }

            expect(e.audit_id).not_to eq(c.audit_id)
        end

        it 'takes into account #inputs names' do
            e = auditable.dup
            allow(e).to receive(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            allow(c).to receive(:inputs) { {input1: 'stuff2' } }
            expect(e.audit_id).to eq(c.audit_id)

            e = auditable.dup
            allow(e).to receive(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            allow(c).to receive(:inputs) { {input2: 'stuff' } }

            expect(e.audit_id).not_to eq(c.audit_id)
        end

        it 'takes into account the given payload' do
            id = auditable.audit_id( '1' )
            expect(auditable.audit_id( '2' )).not_to eq(id)
        end
    end

    describe '#coverage_id' do
        let(:action) { "#{url}/action" }

        it 'takes into account #action' do
            e = auditable.dup
            allow(e).to receive(:action) { action }

            c = auditable.dup
            allow(c).to receive(:action) { "#{action}2" }

            expect(e.coverage_id).not_to eq(c.coverage_id)
        end

        it 'takes into account #type' do
            e = auditable.dup
            allow(e).to receive(:type) { :blah }

            c = auditable.dup
            allow(c).to receive(:type) { :blooh }

            expect(e.coverage_id).not_to eq(c.coverage_id)
        end

        it 'takes into account #inputs names' do
            e = auditable.dup
            allow(e).to receive(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            allow(c).to receive(:inputs) { {input1: 'stuff2' } }
            expect(e.coverage_id).to eq(c.coverage_id)

            e = auditable.dup
            allow(e).to receive(:inputs) { {input1: 'stuff' } }

            c = auditable.dup
            allow(c).to receive(:inputs) { {input2: 'stuff' } }

            expect(e.coverage_id).not_to eq(c.coverage_id)
        end
    end

    describe '#coverage_hash' do
        it 'returns the String#persistent_hash of #coverage_id' do
            expect(auditable.coverage_hash).to eq(auditable.coverage_id.persistent_hash)
        end
    end

    describe '#audit' do
        context 'when the response is out of scope' do
            it 'ignores it' do
                called = nil

                allow_any_instance_of(Arachni::HTTP::Response::Scope).to receive(:out?).and_return(true)
                allow_any_instance_of(Arachni::Page::Scope).to receive(:out?).and_return(true)

                auditable.audit( 'stuff',
                                 format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                 skip_original: true
                ) do |_, element|
                    called = true
                end

                run
                expect(called).to be_falsey
            end

            context 'but the host includes the seed' do
                it 'is considered in scope' do
                    called = nil

                    allow_any_instance_of(Arachni::HTTP::Response::Scope).to receive(:out?).and_return(true)
                    allow_any_instance_of(Arachni::Page::Scope).to receive(:out?).and_return(true)
                    allow_any_instance_of(Arachni::URI).to receive(:seed_in_host?).and_return(true)

                    auditable.audit( 'stuff',
                                     format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                     skip_original: true
                    ) do |_, element|
                        called = true
                    end

                    run
                    expect(called).to be_truthy
                end
            end
        end

        context 'when the payloads is' do
            context 'String' do
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
                    expect(injected).to eq(payload)
                end

                context 'with invalid data' do
                    it 'is ignored' do
                        payload = 'stuff-here'
                        called  = 0

                        allow_any_instance_of(auditable.class).to receive(:valid_input_data?) { |instance, i| i != payload }

                        auditable.audit( payload,
                                         format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                         skip_original: true
                        ) { |_, element| called += 1 }
                        run

                        expect(called).to eq(0)
                    end
                end
            end
            context 'Array' do
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
                    expect(injected.uniq.sort).to eq(payloads.sort)
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        expect(auditable.audit( [],
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                          skip_original: true
                        ) do |_, element|
                            injected << element.affected_input_value
                        end).to be_nil

                        run
                        expect(injected).to be_empty
                    end
                end
            end

            context 'Hash' do
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
                    expect(auditable.audit( payloads,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected << element.affected_input_value
                    end).to be_truthy

                    run

                    payloads.delete( :windows )
                    payloads.delete( :aspx )

                    expect(injected.uniq.sort).to eq(payloads.values.flatten.sort)
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        expect(auditable.audit( {},
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end).to be_nil

                        run
                        expect(injected).to be_empty
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
                        expect(auditable.audit( payloads,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                          skip_original: true
                        ) do |_, element|
                            injected << element.affected_input_value
                        end).to be_truthy

                        run

                        expect(injected.uniq.sort).to eq(payloads.values.flatten.sort)
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
                        expect(auditable.audit( payloads,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end).to be_nil

                        run

                        payloads.delete( :windows )
                        payloads.delete( :aspx )

                        expect(injected).to be_empty
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
            describe ':submit' do
                it 'uses them for the #submit call' do
                    options = { cookies: { stuff: 'blah' }}

                    called = false
                    each = proc do |mutation|
                        expect(mutation).to receive(:submit).with(options)
                        called = true
                    end
                    auditable.audit( seed, each_mutation: each, submit: options ){}

                    expect(called).to be_truthy
                end

                it 'forwards :raw_parameters',
                   if: !described_class.ancestors.include?( Arachni::Element::DOM ) do

                    param           = auditable.inputs.keys.first
                    raw_parameters  = nil

                    auditable.audit(
                        'stuff',
                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                        submit: {
                            raw_parameters: [ param ]
                        },
                        skip_original: true
                    ) do |response, _|
                        raw_parameters = response.request.raw_parameters
                    end

                    run

                    expect(raw_parameters).to eq [param]
                end
            end

            describe ':each_mutation' do
                it 'is passed each generated mutation' do
                    skip if !has_parameter_extractor?

                    submitted = nil
                    cnt = 0

                    each_mutation = proc { |_| cnt += 1 }

                    auditable.audit( seed, each_mutation: each_mutation,
                                      skip_original: true,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                        submitted = auditable_extract_parameters( res )
                    end

                    run
                    expect(cnt).to eq(1)
                    auditable.inputs == submitted
                end

                it 'is able to modify mutations on the fly' do
                    skip if !has_parameter_extractor?

                    submitted = nil

                    modified_seed = 'houa'
                    each_mutation = proc do |mutation|
                        mutation.affected_input_value = modified_seed
                    end

                    auditable.audit( seed, each_mutation: each_mutation,
                                      skip_original: true,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                        submitted = auditable_extract_parameters( res )
                    end

                    run
                    expect(submitted.values.first).to eq(modified_seed)
                end

                context 'when it returns one or more elements of the same type' do
                    it 'audits those elements too' do
                        skip if !has_parameter_extractor?

                        injected = []
                        cnt = 0

                        each_mutation = proc do |mutation|
                            m = mutation.dup
                            m.affected_input_value = 'houa'

                            c = mutation.dup
                            c.affected_input_value = 'houa2'

                            [m, c]
                        end

                        auditable.audit( seed, each_mutation: each_mutation,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                            injected << auditable_extract_parameters( res ).values.first
                            cnt += 1
                        end

                        run
                        expect(cnt).to eq(3)
                        expect(injected.sort).to eq([ seed, 'houa', 'houa2'].sort)
                    end
                end
            end

            describe ':skip_like' do
                describe 'Proc' do
                    it 'skips mutations based on the block\'s return value' do
                        audited   = []
                        skip_like = proc { |m| m.affected_input_name != auditable.inputs.keys.first }

                        auditable.audit( seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        run

                        audited.uniq!
                        expect(audited.size).to eq(1)
                        expect(audited).to eq([auditable.inputs.keys.first])
                    end
                end

                describe 'Array' do
                    it 'skips mutations based on the blocks\' return value' do
                        audited   = []
                        skip_like = []
                        skip_like << proc { |m| m.affected_input_name != auditable.inputs.keys.first }

                        auditable.audit( seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        run

                        audited.uniq!
                        expect(audited.size).to eq(1)
                        expect(audited).to      eq([auditable.inputs.keys.first])
                    end
                end
            end

            describe ':format' do
                describe 'Arachni::Check::Auditor::Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        skip if !has_parameter_extractor?

                        injected = nil
                        cnt = 0

                        auditable.audit( seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end

                        run
                        expect(cnt).to eq(1)
                        expect(injected).to eq(seed)
                    end
                end

                describe 'Arachni::Check::Auditor::Format::APPEND' do
                    it 'appends the seed to the existing value of the input' do
                        skip if !has_parameter_extractor?

                        injected = nil
                        cnt = 0

                        auditable.audit( seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::APPEND ] ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end

                        run
                        expect(cnt).to eq(1)
                        expect(injected).to eq(auditable.inputs.values.first + seed)
                    end
                end

                describe 'Arachni::Check::Auditor::Format::NULL' do
                    it 'terminates the seed with a null character',
                       if: described_class != Arachni::Element::Header &&
                            described_class != Arachni::Element::XML &&
                               !described_class.ancestors.include?( Arachni::Element::DOM ) do

                        skip if !has_parameter_extractor?

                        injected = nil
                        cnt = 0
                        auditable.audit( seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::NULL ] ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end

                        run
                        expect(cnt).to eq(1)
                        expect(auditable.decode( injected )).to eq(seed + "\0")
                    end
                end

                describe 'Arachni::Check::Auditor::Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        skip if !has_parameter_extractor?

                        injected = nil
                        cnt = 0

                        format = [ Arachni::Check::Auditor::Format::SEMICOLON ]
                        auditable.audit( seed, skip_original: true, format: format ) do |res, e|
                            injected = auditable_extract_parameters( res )[e.affected_input_name]
                            cnt += 1
                        end
                        run
                        expect(cnt).to eq(1)

                        expect(auditable.decode( injected )).to eq(";" + seed)
                    end
                end
            end

            describe ':redundant' do
                before do
                    @audit_opts = {
                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                        skip_original: true
                    }
                end

                context 'true' do
                    it 'allows redundant audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.audit( seed, @audit_opts.merge( redundant: true )){ cnt += 1 }
                        end
                        run
                        expect(cnt).to eq(5)
                    end
                end

                context 'false' do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.audit( seed, @audit_opts.merge( redundant: false )){ cnt += 1 }
                        end
                        run
                        expect(cnt).to eq(1)
                    end
                end

                context 'default' do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.audit( seed, @audit_opts ){ cnt += 1 }
                        end
                        run
                        expect(cnt).to eq(1)
                    end
                end
            end
        end

        context "when the #{Arachni::OptionGroups::Audit}#exclude_vector_patterns option is set" do
            it 'skips those vectors by name' do
                Arachni::Options.audit.exclude_vector_patterns = auditable.inputs.keys

                audited = []
                expect(auditable.audit( seed, skip_original: true ) do |_, elem|
                    audited << elem.affected_input_name
                end).to be_truthy

                run
                expect(audited).to be_empty
            end
        end

        context "when #{Arachni::OptionGroups::Audit}#vector?" do
            context 'returns true' do
                it 'audits the input' do
                    allow(Arachni::Options.audit).to receive(:vector?){ true }

                    audited = []
                    expect(auditable.audit( seed, skip_original: true ) do |_, elem|
                        audited << elem.affected_input_name
                    end).to be_truthy

                    run
                    expect(audited).not_to be_empty
                end
            end

            context 'returns false' do
                it 'skips the input' do
                    allow(Arachni::Options.audit).to receive(:vector?){ false }

                    audited = []
                    expect(auditable.audit( seed, skip_original: true ) do |_, elem|
                        audited << elem.affected_input_name
                    end).to be_truthy

                    run
                    expect(audited).to be_empty
                end
            end
        end

        context "when #{described_class::Scope}#out?" do
            context 'true' do
                it 'returns immediately' do
                    allow_any_instance_of(described_class::Scope).to receive(:out?) { true }

                    ran = false
                    expect(auditable.audit( seed ) { ran = true }).to be_falsey
                    run
                    expect(ran).to be_falsey
                end
            end
        end

        context 'when the element has no auditable inputs' do
            it 'returns immediately' do
                ran = false
                auditable.inputs = {}
                expect(auditable.audit( seed ) { ran = true }).to be_falsey
                run

                expect(ran).to be_falsey
            end
        end

        context 'when the auditor\'s #skip? method returns true for a mutation' do
            it 'is skipped' do
                ran = false
                expect(auditable.audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy

                Arachni::Element::Capabilities::Auditable.reset

                def auditor.skip?( elem )
                    true
                end

                ran = false
                expect(auditable.audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_falsey

                Arachni::Element::Capabilities::Auditable.reset

                def auditor.skip?( elem )
                    false
                end

                ran = false
                expect(auditable.audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy
            end
        end

        context 'when the element\'s #skip? method returns true for a mutation' do
            it 'is skipped' do
                ran = false
                expect(auditable.audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy

                Arachni::Element::Capabilities::Auditable.reset

                def auditable.skip?( elem )
                    true
                end

                ran = false
                expect(auditable.audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_falsey

                Arachni::Element::Capabilities::Auditable.reset

                def auditable.skip?( elem )
                    false
                end

                ran = false
                expect(auditable.audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy
            end
        end
    end
end
