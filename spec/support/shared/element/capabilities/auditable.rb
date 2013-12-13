shared_examples_for 'auditable' do |options = {}|

    let( :auditable ) { described_class }
    let( :opts ) do
        {
            single_input:   false,
            supports_nulls: true,
            url:            nil
        }.merge( options )
    end

    def load( yaml )
        YAML.load( yaml )
    end

    before :all do
        @url     = options[:url]
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        @opts = {
            url:    @url,
            action: @url + '/submit',
            inputs: { 'param' => 'val' }
        }

        @auditable = described_class.new( @opts )
        @auditable.auditor = @auditor

        @orphan = described_class.new( @opts )

        # will sleep 2 secs before each response
        @sleep = described_class.new( @opts.merge( action: @url + '/sleep' ) )
        @sleep.auditor = @auditor

        @default_inputs = described_class.new( @opts )

        @seed = 'my_seed'
        @default_input_value = @auditable.inputs['param']
    end

    before :each do
        Arachni::Element::Capabilities::Auditable.reset
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash          = nil
            audit_options = {
                skip_original: true,
                format:        [ Arachni::Check::Auditor::Format::STRAIGHT ]
            }

            m = nil
            @auditable.audit( @seed, audit_options ) do |_, mutation|
                hash ||= mutation.to_h
                m    ||= mutation
            end

            @auditable.http.run

            # Test only the data provided by the Auditable mixin.
            %w(url action inputs default_inputs).map { |k| hash[k.to_sym] }.should ==
                [
                    Arachni::Utilities.normalize_url( @opts[:url] ),
                    Arachni::Utilities.normalize_url( @opts[:action] ),
                    { 'param' => 'my_seed' },
                    { 'param' => 'val' }
                ]
        end
    end

    describe '.skip_like' do
        it 'skips elements based on the block\'s return value' do
            audited = false
            @auditable.audit( 'seed' ){ audited = true }
            @auditable.http.run
            audited.should be_true

            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do |element|
                element.action.end_with? '/submit'
            end

            audited = false
            @auditable.audit( 'seed' ){ audited = true }
            @auditable.http.run
            audited.should be_false
        end

        it 'skips element mutations based on the block\'s return value' do
            expected  = 4
            expected += 1 if @auditable.is_a?( Arachni::Form )
            expected -= 2 if !opts[:supports_nulls]

            i = 0
            (@auditable.audit( 'seed' ){ i += 1 }).should be_true
            @auditable.http.run
            i.should == expected

            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do |element|
                element.affected_input_name == 'param'
            end

            i = 0
            (@auditable.audit( 'seed' ){ i += 1}).should be_true
            @auditable.http.run
            i.should == (@auditable.is_a?( Arachni::Form ) ? 1 : 0)
        end
    end

    describe '#has_inputs?' do
        before do
            @has_inputs = auditable.new(
                url: @url,
                inputs: { 'param' => 'val', 'param2' => 'val2' }
            )
            @keys       = @has_inputs.inputs.keys
            @sym_keys   = @keys.map( &:to_sym )

            @non_existent_keys     = @keys.map { |k| "#{k}1" }
            @non_existent_sym_keys = @sym_keys.map { |k| "#{k}1".to_sym }
        end
        context 'when the given inputs are' do
            context 'Variable arguments' do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        @keys.each do |k|
                            @has_inputs.has_inputs?( k.to_s.to_sym ).should be_true
                            @has_inputs.has_inputs?( k.to_s ).should be_true
                        end

                        @has_inputs.has_inputs?( *@sym_keys ).should be_true
                        @has_inputs.has_inputs?( *@keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        @has_inputs.has_inputs?( *@non_existent_sym_keys ).should be_false
                        @has_inputs.has_inputs?( *@non_existent_keys ).should be_false

                        @has_inputs.has_inputs?( @non_existent_keys.first ).should be_false
                    end
                end
            end

            context Array do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        @has_inputs.has_inputs?( @sym_keys ).should be_true
                        @has_inputs.has_inputs?( @keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        @has_inputs.has_inputs?( @non_existent_sym_keys ).should be_false
                        @has_inputs.has_inputs?( @non_existent_keys ).should be_false
                    end
                end
            end

            context Hash do
                context 'when it has the given inputs (names and values)' do
                    it 'returns true' do
                        hash     = @has_inputs.inputs.
                            inject( {} ) { |h, (k, v)| h[k] = v; h}

                        hash_sym = @has_inputs.inputs.
                            inject( {} ) { |h, (k, v)| h[k.to_sym] = v; h}

                        @has_inputs.has_inputs?( hash_sym ).should be_true
                        @has_inputs.has_inputs?( hash ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        hash     = @has_inputs.inputs.
                            inject( {} ) { |h, (k, v)| h[k] = "#{v}1"; h}

                        hash_sym = @has_inputs.inputs.
                            inject( {} ) { |h, (k, v)| h[k.to_sym] = "#{v}1"; h}

                        @has_inputs.has_inputs?( hash_sym ).should be_false
                        @has_inputs.has_inputs?( hash ).should be_false
                    end
                end
            end
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given element' do
            @auditable.platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#auditable' do
        it 'returns a frozen hash of auditable inputs' do
            @auditable.inputs.should == { 'param' => 'val' }

            raised = false
            begin
                @auditable.inputs['stuff'] = true
            rescue
                raised = true
            end

            @auditable.inputs.should == { 'param' => 'val' }

            raised.should be_true
        end
    end

    describe '#auditable=' do
        it 'assigns a hash of auditable inputs' do
            @auditable.inputs.should == { 'param' => 'val' }

            a = @auditable.dup
            a.inputs = { 'param1' => 'val1' }
            a.inputs.should == { 'param1' => 'val1' }
            a.should_not == @auditable
        end

        it 'converts all inputs to strings' do
            e = auditable.new( url: @url, inputs: { 'key' => nil } )
            e.inputs.should == { 'key' => '' }
        end
    end

    describe '#update' do
        it 'updates the auditable inputs using the given hash and return self' do
            a = @auditable.dup

            updates =   if opts[:single_input]
                            { 'param' => 'val1' }
                        else
                            { 'param' => 'val1', 'another_param' => 'val3' }
                        end
            a.update( updates )

            a.inputs.should == updates
            a.hash.should_not == @auditable.hash

            c = a.dup
            cupdates = { 'param' => '' }
            a.update( cupdates )
            a.inputs.should == updates.merge( cupdates )
            c.should_not == a

            if !opts[:single_input]
                c = a.dup
                c.update( stuff: '1' ).update( other_stuff: '2' )
                c['stuff'].should == '1'
                c['other_stuff'].should == '2'
            end
        end

        it 'converts all inputs to strings' do
            e = auditable.new( url: @url, inputs: { 'key' => 'stuff' } )
            e.update( { 'key' => nil } )
            e.inputs.should == { 'key' => '' }
        end
    end

    describe '#changes' do
        it 'returns the changes the inputs have sustained' do
            if !opts[:single_input]
                [
                    { 'param' => 'val1', 'another_param' => 'val3' },
                    { 'another_param' => 'val3' },
                    { 'new stuff' => 'houa!' },
                    { 'new stuff' => 'houa!' },
                    {}
                ].each do |updates|
                    a = @auditable.dup
                    a.update( updates )
                    a.changes.should == updates
                end
            else
                [
                    { 'param' => 'val1' },
                    { 'param' => 'val3' },
                    {}
                ].each do |updates|
                    a = @auditable.dup
                    a.update( updates )
                    a.changes.should == updates
                end
            end
        end
    end

    describe '#[]' do
        it ' serves as a reader to the #auditable hash' do
            e = auditable.new( url: @url, inputs: { 'key' => 'stuff', 'key2' => 'val' } )
            e['key'].should == 'stuff'
        end
    end

    describe '#[]=' do
        it 'serves as a writer to the #auditable hash' do
            e = auditable.new( url: @url, inputs: { 'key' => 'stuff', 'key2' => 'val' } )
            h = e.hash

            e['key'] = 'val2'

            h.should_not == e.hash

            e['key'].should == e.inputs['key']
            e['key'].should == 'val2'
        end
    end

    describe '#default_inputs' do
        it 'should be frozen' do
            orig_auditable = @default_inputs.inputs.dup
            is_frozen = false
            begin
                @default_inputs.default_inputs['ff'] = 'ffss'
            rescue RuntimeError
                is_frozen = true
            end
            is_frozen.should be_true
            @default_inputs.default_inputs.should == orig_auditable
        end
        context 'when auditable' do
            context 'has been modified' do
                it 'returns original input name/vals' do
                    orig_auditable = @default_inputs.inputs.dup
                    @default_inputs.inputs = {}
                    @default_inputs.default_inputs.should == orig_auditable
                    @default_inputs.inputs = orig_auditable.dup
                end
            end
            context 'has not been modified' do
                it 'returns #auditable' do
                    @default_inputs.default_inputs.should == @default_inputs.inputs
                end
            end
        end
        it 'aliased to #original' do
            @default_inputs.default_inputs.should == @default_inputs.default_inputs
        end
    end

    describe '#reset' do
        it 'returns the element to its original state' do
            orig = @default_inputs.dup

            k, v = orig.inputs.keys.first, 'value'

            @default_inputs.update( k => v )
            @default_inputs.affected_input_name = k
            @default_inputs.affected_input_value = v
            @default_inputs.seed = v

            @default_inputs.inputs.should_not == orig.inputs
            @default_inputs.affected_input_name.should_not == orig.affected_input_name
            @default_inputs.affected_input_value.should_not == orig.affected_input_value
            @default_inputs.seed.should_not == orig.seed

            @default_inputs.reset

            @default_inputs.inputs.should == orig.inputs

            @default_inputs.affected_input_name.should == orig.affected_input_name
            @default_inputs.affected_input_name.should be_nil

            @default_inputs.affected_input_value.should == orig.affected_input_value
            @default_inputs.affected_input_value.should be_nil

            @default_inputs.seed.should == orig.seed
            @default_inputs.seed.should be_nil
        end
    end

    describe '#remove_auditor' do
        it 'removes the auditor' do
            @default_inputs.auditor = :some_auditor
            @default_inputs.auditor.should == :some_auditor
            @default_inputs.remove_auditor
            @default_inputs.auditor.should be_nil
        end
    end

    describe '#orphan?' do
        context 'when it has no auditor' do
            it 'returns true' do
                @orphan.orphan?.should be_true
            end
        end
        context 'when it has an auditor' do
            it 'returns true' do
                @auditable.orphan?.should be_false
            end
        end
    end

    describe '#submit' do
        it 'submits the element using its auditable inputs as params' do
            submitted = nil

            @auditable.submit do |res|
                submitted = load( res.body )
            end

            @auditor.http.run
            @auditable.inputs.should == submitted
        end

        it 'assigns the auditable element as the request performer' do
            response = nil
            @auditable.submit { |res| response = res }

            @auditor.http.run
            response.request.performer.should == @auditable
        end
    end

    describe '#audit' do
        before( :each ) do
            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Platform::Manager.reset
        end

        context 'when no block is given' do
            it 'raises ArgumentError' do
                expect { @auditable.audit( 'stuff' ) }.to raise_error ArgumentError
            end
        end

        context 'when the payloads is' do
            context String do
                it 'injects the given payload' do
                    payload = 'stuff-here'
                    injected = nil

                    @auditable.audit( payload,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected = element.affected_input_value
                    end

                    @auditor.http.run
                    injected.should == payload
                end
            end
            context Array do
                it 'injects all supplied payload' do
                    payloads = [ 'stuff-here', 'stuff-here-2' ]
                    injected = []

                    @auditable.audit( payloads,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected << element.affected_input_value
                    end

                    @auditor.http.run
                    injected.uniq.sort.should == payloads.sort
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        @auditable.audit( [],
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                          skip_original: true
                        ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_nil

                        @auditor.http.run
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

                    @auditable.platforms.update %w(unix php apache)
                    @auditable.audit( payloads,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                      skip_original: true
                    ) do |_, element|
                        injected << element.affected_input_value
                    end.should be_true

                    @auditor.http.run

                    payloads.delete( :windows )
                    payloads.delete( :aspx )

                    injected.uniq.sort.should == payloads.values.flatten.sort
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        @auditable.audit( {},
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_nil

                        @auditor.http.run
                        injected.should be_empty
                    end
                end

                context 'and the element has no identified platforms' do
                    it 'injects all given payloads' do
                        payloads = {
                            linux:   [ 'linux-payload-1', 'linux-payload-2' ],
                            freebsd: 'freebsd-payload',
                            openbsd: [ 'openbsd-payload-1', 'openbsd-payload-2' ],
                            php:     [ 'php-payload-1', 'php-payload-2' ],
                            apache:  'apache-payload',
                            windows: 'windows-payload',
                            aspx:    [ 'aspx-payload-1', 'aspx-payload-2' ]
                        }

                        injected = []

                        @auditable.audit( payloads,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                          skip_original: true
                        ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_true

                        @auditor.http.run

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

                        @auditable.platforms.update %w(unix php apache)
                        @auditable.audit( payloads,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end.should be_nil

                        @auditor.http.run

                        payloads.delete( :windows )
                        payloads.delete( :aspx )

                        injected.should be_empty
                    end
                end
            end

            describe 'other' do
                it 'raises ArgumentError' do
                    expect do
                        @auditable.audit( :stuff,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |_, element|
                            injected << element.affected_input_value
                        end
                    end.to raise_error ArgumentError
                end
            end
        end

        context 'when called with option' do
            describe :each_mutation do
                it 'is passed each generated mutation' do
                    submitted = nil
                    cnt = 0

                    each_mutation = proc { |_| cnt += 1 }

                    @auditable.audit( @seed, each_mutation: each_mutation,
                                      skip_original: true,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                        submitted = load( res.body )
                    end

                    @auditor.http.run
                    cnt.should == 1
                    @auditable.inputs == submitted
                end

                it 'is able to modify mutations on the fly' do
                    submitted = nil

                    modified_seed = 'houa!'
                    each_mutation = proc do |mutation|
                        mutation.affected_input_value = modified_seed
                    end

                    @auditable.audit( @seed, each_mutation: each_mutation,
                                      skip_original: true,
                                      format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                        submitted = load( res.body )
                    end

                    @auditor.http.run
                    submitted.values.first.should == modified_seed
                end

                context 'when it returns one or more elements of the same type' do
                    it 'audits those elements too' do
                        injected = []
                        cnt = 0

                        each_mutation = proc do |mutation|
                            m = mutation.dup
                            m.affected_input_value = 'houa!'

                            c = mutation.dup
                            c.affected_input_value = 'houa2!'

                            [m, c]
                        end

                        @auditable.audit( @seed, each_mutation: each_mutation,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, _|
                            injected << load( res.body ).values.first
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 3
                        injected.sort.should == [ @seed, 'houa!', 'houa2!'].sort
                    end
                end
            end

            describe :skip_like do
                describe Proc do
                    it 'skips mutations based on the block\'s return value' do
                        auditable = described_class.new(
                            url:    @url + '/submit',
                            inputs: {
                                'param'  => 'val',
                                'param2' => 'val2'
                            }
                        )
                        auditable.auditor = @auditor

                        audited   = []
                        skip_like = proc { |m| m.affected_input_name != 'param' }

                        auditable.audit( @seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        @auditor.http.run

                        audited.uniq!
                        audited.size.should == 1
                        audited.should == ['param']
                    end
                end

                describe Array do
                    it 'skips mutations based on the blocks\' return value' do
                        auditable = described_class.new(
                            url:    @url + '/submit',
                            inputs: {
                                'param'  => 'val',
                                'param2' => 'val2',
                                'param3' => 'val3'
                            }
                        )
                        auditable.auditor = @auditor

                        audited   = []
                        skip_like = []
                        skip_like << proc { |m| m.affected_input_name == 'param2' }
                        skip_like << proc { |m| m.affected_input_name == 'param3' }

                        auditable.audit( @seed, skip_original: true, skip_like: skip_like ) do |_, m|
                            audited << m.affected_input_name
                        end

                        @auditor.http.run

                        audited.uniq!
                        audited.size.should == 1
                        audited.should      == ['param']
                    end
                end
            end

            describe :format do
                describe 'Arachni::Check::Auditor::Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        injected = nil
                        cnt = 0

                        @auditable.audit( @seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::STRAIGHT ] ) do |res, e|
                            injected = load( res.body )[e.affected_input_name]
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @seed
                    end
                end

                describe 'Arachni::Check::Auditor::Format::APPEND' do
                    it 'appends the seed to the existing value of the input' do
                        injected = nil
                        cnt = 0

                        @auditable.audit( @seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::APPEND ] ) do |res, e|
                            injected = load( res.body )[e.affected_input_name]
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @default_input_value + @seed
                    end
                end

                describe 'Arachni::Check::Auditor::Format::NULL' do
                    it 'terminates the seed with a null character',
                       if: described_class != Arachni::Element::Header  do

                        injected = nil
                        cnt = 0
                        @auditable.audit( @seed,
                                          skip_original: true,
                                          format: [ Arachni::Check::Auditor::Format::NULL ] ) do |res, e|
                            injected = load( res.body )[e.affected_input_name]
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 1
                        auditable.decode( injected ).should == @seed + "\0"
                    end
                end

                describe 'Arachni::Check::Auditor::Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        injected = nil
                        cnt = 0

                        format = [ Arachni::Check::Auditor::Format::SEMICOLON ]
                        @auditable.audit( @seed, skip_original: true, format: format ) do |res, e|
                            injected = load( res.body )[e.affected_input_name]
                            cnt += 1
                        end
                        @auditor.http.run
                        cnt.should == 1

                        auditable.decode( injected ).should == ";" + @seed
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
                            @auditable.audit( @seed, @audit_opts.merge( redundant: true )){ cnt += 1 }
                        end
                        @auditor.http.run
                        cnt.should == 5
                    end
                end

                context false do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            @auditable.audit( @seed, @audit_opts.merge( redundant: false )){ cnt += 1 }
                        end
                        @auditor.http.run
                        cnt.should == 1
                    end
                end

                context 'default' do
                    it 'does not allow redundant requests/audits' do
                        cnt = 0
                        5.times do |i|
                            @auditable.audit( @seed, @audit_opts ){ cnt += 1 }
                        end
                        @auditor.http.run
                        cnt.should == 1
                    end
                end
            end

            describe :mode do
                context 'nil' do
                    it 'performs all HTTP requests asynchronously' do
                        before = Time.now
                        @sleep.audit( @seed ){}
                        @auditor.http.run

                        (Time.now - before).to_i.should == 2
                    end
                end

                context :async do
                    it 'performs all HTTP requests asynchronously' do
                        before = Time.now
                        @sleep.audit( @seed, mode: :async ){}
                        @auditor.http.run

                        # should take as long as the longest request
                        # and since we're doing this locally the longest
                        # request must take less than a second.
                        #
                        # so it should be 2 when converted into an Int
                        (Time.now - before).to_i.should == 2
                    end
                end

                context :sync do
                    it 'performs all HTTP requests synchronously' do
                        before = Time.now
                        @sleep.audit( @seed, mode: :sync ){}
                        @auditor.http.run

                        (Time.now - before).should > 4.0
                    end
                end

            end
        end

        context 'when the exclude_vectors option is set' do
            it 'skips those vectors by name' do
                e = auditable.new(
                    url: @url + '/submit',
                    inputs: {
                        'include_this' => 'param', 'exclude_this' => 'param'
                    }
                )

                Arachni::Options.exclude_vectors << 'exclude_this'

                audited = []
                e.audit( @seed, skip_original: true ) { |_, elem| audited << elem.affected_input_name  }.should be_true
                e.http.run

                audited.uniq.should == %w(include_this)
            end
        end
        context 'when called with no opts' do
            it 'uses the defaults' do
                cnt = 0
                @auditable.audit( @seed, skip_original: true  ) { cnt += 1 }
                @auditor.http.run
                cnt.should == (opts[:supports_nulls] ? 4 : 2)
            end
        end

        context 'when the action matches a #skip_path? rule' do
            it 'returns immediately' do
                ran = false
                @auditable.audit( @seed ) { ran = true }
                @auditor.http.run
                ran.should be_true

                Arachni::Element::Capabilities::Auditable.reset

                opts = Arachni::Options.instance
                opts.exclude << @auditable.action

                ran = false
                @auditable.audit( @seed ) { ran = true }
                @auditor.http.run
                ran.should be_false

                opts.exclude.clear

                Arachni::Element::Capabilities::Auditable.reset

                ran = false
                @auditable.audit( @seed ) { ran = true }
                @auditor.http.run
                ran.should be_true
            end
        end

        context 'when the element has no auditable inputs' do
            it 'returns immediately' do
                e = auditable.new( url: @url + '/submit' )

                ran = false
                e.audit( @seed ) { ran = true }.should be_false
                e.http.run

                ran.should be_false
            end
        end

        context 'when the auditor\'s #skip? method returns true for a mutation' do
            it 'is skipped' do

                ran = false
                @auditable.audit( @seed ) { ran = true }.should be_true
                @auditor.http.run
                ran.should be_true

                Arachni::Element::Capabilities::Auditable.reset

                def @auditor.skip?( elem )
                    true
                end

                ran = false
                @auditable.audit( @seed ) { ran = true }.should be_true
                @auditor.http.run
                ran.should be_false

                Arachni::Element::Capabilities::Auditable.reset

                def @auditor.skip?( elem )
                    false
                end

                ran = false
                @auditable.audit( @seed ) { ran = true }.should be_true
                @auditor.http.run
                ran.should be_true
            end
        end

        context 'when the element\'s #skip? method returns true for a mutation' do
            it 'is skipped' do

                ran = false
                @auditable.audit( @seed ) { ran = true }.should be_true
                @auditor.http.run
                ran.should be_true

                Arachni::Element::Capabilities::Auditable.reset

                def @auditable.skip?( elem )
                    true
                end

                ran = false
                @auditable.audit( @seed ) { ran = true }.should be_true
                @auditor.http.run
                ran.should be_false

                Arachni::Element::Capabilities::Auditable.reset

                def @auditable.skip?( elem )
                    false
                end

                ran = false
                @auditable.audit( @seed ) { ran = true }.should be_true
                @auditor.http.run
                ran.should be_true
            end
        end

        describe '.restrict_to_elements' do
            after { Arachni::Element::Capabilities::Auditable.reset_instance_scope }

            context 'when set' do
                it 'restricts the audit to the provided elements' do
                    scope_id_arr = [ @auditable.scope_audit_id ]
                    Arachni::Element::Capabilities::Auditable.restrict_to_elements( scope_id_arr )
                    performed = false
                    @sleep.audit( '' ){ performed = true }
                    @sleep.http.run
                    performed.should be_false

                    performed = false
                    @auditable.audit( '' ){ performed = true }
                    @auditable.http.run
                    performed.should be_true
                end

                describe '#override_instance_scope' do

                    after { @sleep.reset_scope_override }

                    context 'when called' do
                        it 'overrides scope restrictions' do
                            scope_id_arr = [ @auditable.scope_audit_id ]
                            Arachni::Element::Capabilities::Auditable.restrict_to_elements( scope_id_arr )
                            performed = false
                            @sleep.audit( '' ){ performed = true }
                            @sleep.http.run
                            performed.should be_false

                            @sleep.override_instance_scope
                            performed = false
                            @sleep.audit( '' ){ performed = true }
                            @sleep.http.run
                            performed.should be_true
                        end

                        describe '#override_instance_scope?' do
                            it 'returns true' do
                                @sleep.override_instance_scope
                                @sleep.override_instance_scope?.should be_true
                            end
                        end
                    end

                    context 'when not called' do
                        describe '#override_instance_scope?' do
                            it 'returns false' do
                                @sleep.override_instance_scope?.should be_false
                            end
                        end
                    end
                end
            end

            context 'when not set' do
                it 'does not impose audit restrictions' do
                    performed = false
                    @sleep.audit( '' ){ performed = true }
                    @sleep.http.run
                    performed.should be_true

                    performed = false
                    @auditable.audit( '' ){ performed = true }
                    @auditable.http.run
                    performed.should be_true
                end
            end
        end
    end
end
