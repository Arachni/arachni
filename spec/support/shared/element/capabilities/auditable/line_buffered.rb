shared_examples_for 'line_buffered_auditable' do

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

    describe '#line_buffered_audit' do

        let(:auditable) do
            super().tap { |s| s.action = "#{s.action}/line_buffered" }
        end

        def line_buffered_auditable_extract_parameters( res )
            res = res.dup
            res.body = res.body.split( 'START_PARAMS' ).last
            res.body = res.body.split( 'END_PARAMS' ).first
            auditable_extract_parameters res
        end

        it 'reads audit responses in chunks of full lines' do
            payload  = 'stuff-here'
            mutation = nil

            lines = []
            auditable.buffered_audit(
                payload,
                format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                skip_original: true
            ) do |r, m|
                mutation ||= m
                lines << r.body.strip
            end

            run

            received_body = (lines.join("\n") << "\n")

            expect(lines.size).to be > 1
            expect(received_body).to eq mutation.submit( mode: :sync ).body
        end

        it 'passes a complete flag to the block' do
            payload   = 'stuff-here'
            injected  = nil
            mutation  = nil
            completes = []
            lines     = []

            auditable.buffered_audit(
                payload,
                format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                skip_original: true
            ) do |r, m, c|
                completes << c
                mutation ||= m
                lines << r.body.strip
            end

            run

            received_body = (lines.join("\n") << "\n")
            vanilla_body  = mutation.submit( mode: :sync ).body

            expect(completes.pop).to be_truthy
            expect(completes.uniq).to eq [false]
            expect(lines.size).to be > 1
            expect(received_body).to eq vanilla_body
        end

        context 'when no block is given' do
            it 'raises ArgumentError' do
                expect { auditable.line_buffered_audit( 'stuff' ) }.to raise_error ArgumentError
            end
        end

        context 'when the response is out of scope' do
            it 'ignores it' do
                called = nil

                allow_any_instance_of(Arachni::HTTP::Response::Scope).to receive(:out?).and_return(true)
                allow_any_instance_of(Arachni::Page::Scope).to receive(:out?).and_return(true)

                auditable.line_buffered_audit( 'stuff',
                                               format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                               skip_original: true
                ) do |_, element, completed|
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

                    auditable.line_buffered_audit( 'stuff',
                                                   format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                                   skip_original: true
                    ) do |_, element, completed|
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

                    auditable.line_buffered_audit( payload,
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

                        auditable.line_buffered_audit( payload,
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

                    auditable.line_buffered_audit( payloads,
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
                        expect(auditable.line_buffered_audit( [],
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
                    expect(auditable.line_buffered_audit( payloads,
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
                        expect(auditable.line_buffered_audit( {},
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
                        expect(auditable.line_buffered_audit( payloads,
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
                        expect(auditable.line_buffered_audit( payloads,
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
                        auditable.line_buffered_audit( :stuff,
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
                    auditable.line_buffered_audit( seed, each_mutation: each, submit: options ){}

                    expect(called).to be_truthy
                end

                it 'forwards :raw_parameters' do
                    param           = auditable.inputs.keys.first
                    raw_parameters  = nil

                    auditable.line_buffered_audit(
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
                it 'is able to modify mutations on the fly' do
                    skip if !has_parameter_extractor?

                    modified_seed = 'houa'
                    each_mutation = proc do |mutation|
                        mutation.affected_input_value = modified_seed
                    end

                    body     = ''
                    response = nil
                    auditable.line_buffered_audit(
                        seed,
                        each_mutation: each_mutation,
                        skip_original: true,
                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                    ) do |r|
                        response ||= r
                        body << r.body
                    end

                    run

                    response.body = body
                    submitted = line_buffered_auditable_extract_parameters( response )

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

                        bodies   = {}
                        response = nil
                        auditable.line_buffered_audit(
                            seed,
                            each_mutation: each_mutation,
                            skip_original: true,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        ) do |r, e, completed|

                            response ||= r

                            bodies[e.affected_input_value] ||= ''
                            bodies[e.affected_input_value] << r.body

                            next if !completed
                            cnt += 1
                        end

                        run

                        bodies.values.each do |body|
                            response.body = body
                            injected << line_buffered_auditable_extract_parameters(
                                response
                            ).values.first
                        end

                        expect(cnt).to eq(3)
                        expect(bodies.keys.sort).to eq([ seed, 'houa', 'houa2'].sort)
                        expect(injected.sort).to eq([ seed, 'houa', 'houa2'].sort)
                    end
                end
            end

            describe ':skip_like' do
                describe 'Proc' do
                    it 'skips mutations based on the block\'s return value' do
                        audited   = []
                        skip_like = proc { |m| m.affected_input_name != auditable.inputs.keys.first }

                        auditable.line_buffered_audit( seed, skip_original: true, skip_like: skip_like ) do |_, m|
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

                        auditable.line_buffered_audit( seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        run

                        audited.uniq!
                        expect(audited.size).to eq(1)
                        expect(audited).to eq([auditable.inputs.keys.first])
                    end
                end
            end

            describe ':format' do
                describe 'Arachni::Check::Auditor::Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        skip if !has_parameter_extractor?

                        cnt      = 0
                        response = nil
                        body     = ''
                        mutation = nil
                        auditable.line_buffered_audit(
                            seed,
                            skip_original: true,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        ) do |r, e, completed|
                            mutation ||= e
                            response ||= r
                            body << r.body

                            cnt += 1 if completed
                        end

                        run

                        response.body = body
                        injected = line_buffered_auditable_extract_parameters(
                            response
                        )[mutation.affected_input_name]

                        expect(cnt).to eq(1)
                        expect(injected).to eq(seed)
                    end
                end

                describe 'Arachni::Check::Auditor::Format::APPEND' do
                    it 'appends the seed to the existing value of the input' do
                        skip if !has_parameter_extractor?

                        cnt      = 0
                        response = nil
                        body     = ''
                        mutation = nil
                        auditable.line_buffered_audit(
                            seed,
                            skip_original: true,
                            format: [ Arachni::Check::Auditor::Format::APPEND ]
                        ) do |r, e, completed|
                            mutation ||= e
                            response ||= r
                            body << r.body

                            cnt += 1 if completed
                        end

                        run

                        response.body = body
                        injected = line_buffered_auditable_extract_parameters(
                            response
                        )[mutation.affected_input_name]

                        expect(cnt).to eq(1)
                        expect(injected).to eq(auditable.inputs.values.first + seed)
                    end
                end

                describe 'Arachni::Check::Auditor::Format::NULL' do
                    it 'terminates the seed with a null character',
                       if: described_class != Arachni::Element::Header &&
                               described_class != Arachni::Element::XML  do

                        skip if !has_parameter_extractor?

                        cnt      = 0
                        response = nil
                        body     = ''
                        mutation = nil
                        auditable.line_buffered_audit(
                            seed,
                            skip_original: true,
                            format: [ Arachni::Check::Auditor::Format::NULL ]
                        ) do |r, e, completed|
                            mutation ||= e
                            response ||= r
                            body << r.body

                            cnt += 1 if completed
                        end

                        run

                        response.body = body
                        injected = line_buffered_auditable_extract_parameters(
                            response
                        )[mutation.affected_input_name]

                        expect(cnt).to eq(1)
                        expect(auditable.decode( injected )).to eq(seed + "\0")
                    end
                end

                describe 'Arachni::Check::Auditor::Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        skip if !has_parameter_extractor?

                        cnt      = 0
                        response = nil
                        body     = ''
                        mutation = nil
                        auditable.line_buffered_audit(
                            seed,
                            skip_original: true,
                            format: [ Arachni::Check::Auditor::Format::SEMICOLON ]
                        ) do |r, e, completed|
                            mutation ||= e
                            response ||= r
                            body << r.body

                            cnt += 1 if completed
                        end

                        run

                        response.body = body
                        injected = line_buffered_auditable_extract_parameters(
                            response
                        )[mutation.affected_input_name]

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
                            auditable.line_buffered_audit(
                                seed,
                                @audit_opts.merge( redundant: true )
                            ) do |_, _, completed|
                                cnt += 1 if completed
                            end
                        end

                        run

                        expect(cnt).to eq(5)
                    end
                end

                context 'false' do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.line_buffered_audit(
                                seed,
                                @audit_opts.merge( redundant: false )
                            ) do |_, _, completed|
                                cnt += 1 if completed
                            end
                        end

                        run

                        expect(cnt).to eq(1)
                    end
                end

                context 'default' do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            auditable.line_buffered_audit(
                                seed,
                                @audit_opts
                            ) do |_, _, completed|
                                cnt += 1 if completed
                            end
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
                expect(auditable.line_buffered_audit( seed, skip_original: true ) do |_, elem|
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
                    expect(auditable.line_buffered_audit( seed, skip_original: true ) do |_, elem|
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
                    expect(auditable.line_buffered_audit( seed, skip_original: true ) do |_, elem|
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
                    expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_falsey
                    run
                    expect(ran).to be_falsey
                end
            end
        end

        context 'when the element has no auditable inputs' do
            it 'returns immediately' do
                ran = false
                auditable.inputs = {}
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_falsey
                run

                expect(ran).to be_falsey
            end
        end

        context 'when the auditor\'s #skip? method returns true for a mutation' do
            it 'is skipped' do
                ran = false
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy

                Arachni::Element::Capabilities::Auditable.reset

                def auditor.skip?( elem )
                    true
                end

                ran = false
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_falsey

                Arachni::Element::Capabilities::Auditable.reset

                def auditor.skip?( elem )
                    false
                end

                ran = false
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy
            end
        end

        context 'when the element\'s #skip? method returns true for a mutation' do
            it 'is skipped' do
                ran = false
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy

                Arachni::Element::Capabilities::Auditable.reset

                def auditable.skip?( elem )
                    true
                end

                ran = false
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_falsey

                Arachni::Element::Capabilities::Auditable.reset

                def auditable.skip?( elem )
                    false
                end

                ran = false
                expect(auditable.line_buffered_audit( seed ) { ran = true }).to be_truthy
                run
                expect(ran).to be_truthy
            end
        end
    end
end
