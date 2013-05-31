shared_examples_for 'auditable' do |options = {}|

    let( :auditable ) { described_class }
    let( :opts ) do
        {
            single_input: false,
            url:          nil
        }.merge( options )
    end

    def load( yaml )
        YAML.load( yaml )
    end

    before :all do
        @url     = options[:url]
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        @auditable = described_class.new( @url + '/submit', 'param' => 'val' )
        @auditable.auditor = @auditor

        @orphan = described_class.new( @url + '/submit', 'param' => 'val' )

        # will sleep 2 secs before each response
        @sleep = described_class.new( @url + '/sleep', 'param' => 'val' )
        @sleep.auditor = @auditor

        @orig = described_class.new( @url, 'param' => 'val' )

        @seed = 'my_seed'
        @default_input_value = @auditable.auditable['param']
    end

    describe '#skip_like' do
        it 'skips elements based on the block\'s return value' do
            (@auditable.audit( 'seed' ){}).should be_true
            Arachni::Element::Capabilities::Auditable.reset
            Arachni::Element::Capabilities::Auditable.skip_like do |element|
                element.action.end_with? '/submit'
            end
            (@auditable.audit( 'seed' ){}).should be_false
        end
    end

    describe '#use_anonymous_auditor' do
        it 'uses an anonymous auditor' do
            elem = auditable.new( @url, 'param' => 'val' )
            elem.auditor.should be_nil
            elem.use_anonymous_auditor
            elem.auditor.should be_true
            elem.auditor.fancy_name.should be_true
        end
    end

    describe '#has_inputs?' do
        before do
            @has_inputs = auditable.new( @url, { 'param' => 'val', 'param2' => 'val2' } )
            @keys       = @has_inputs.auditable.keys
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
                        hash     = @has_inputs.auditable.
                            inject( {} ) { |h, (k, v)| h[k] = v; h}

                        hash_sym = @has_inputs.auditable.
                            inject( {} ) { |h, (k, v)| h[k.to_sym] = v; h}

                        @has_inputs.has_inputs?( hash_sym ).should be_true
                        @has_inputs.has_inputs?( hash ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        hash     = @has_inputs.auditable.
                            inject( {} ) { |h, (k, v)| h[k] = "#{v}1"; h}

                        hash_sym = @has_inputs.auditable.
                            inject( {} ) { |h, (k, v)| h[k.to_sym] = "#{v}1"; h}

                        @has_inputs.has_inputs?( hash_sym ).should be_false
                        @has_inputs.has_inputs?( hash ).should be_false
                    end
                end
            end
        end
    end

    describe '#auditable' do
        it 'returns a frozen hash of auditable inputs' do
            @auditable.auditable.should == { 'param' => 'val' }

            raised = false
            begin
                @auditable.auditable['stuff'] = true
            rescue
                raised = true
            end

            @auditable.auditable.should == { 'param' => 'val' }

            raised.should be_true
        end
    end

    describe '#auditable=' do
        it 'assigns a hash of auditable inputs' do
            @auditable.auditable.should == { 'param' => 'val' }

            a = @auditable.dup
            a.auditable = { 'param1' => 'val1' }
            a.auditable.should == { 'param1' => 'val1' }
            a.should_not == @auditable
        end

        it 'converts all inputs to strings' do
            e = auditable.new( @url, { 'key' => nil } )
            e.auditable.should == { 'key' => '' }
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

            a.auditable.should == updates
            a.hash.should_not == @auditable.hash

            c = a.dup
            cupdates = { 'param' => '' }
            a.update( cupdates )
            a.auditable.should == updates.merge( cupdates )
            c.should_not == a

            if !opts[:single_input]
                c = a.dup
                c.update( stuff: '1' ).update( other_stuff: '2' )
                c['stuff'].should == '1'
                c['other_stuff'].should == '2'
            end
        end

        it 'converts all inputs to strings' do
            e = auditable.new( @url, 'key' => 'stuff' )
            e.update( { 'key' => nil } )
            e.auditable.should == { 'key' => '' }
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
            e = auditable.new( @url, { 'key' => 'stuff', 'key2' => 'val' } )
            e['key'].should == 'stuff'
        end
    end

    describe '#[]=' do
        it 'serves as a writer to the #auditable hash' do
            e = auditable.new( @url, { 'key' => 'stuff', 'key2' => 'val' } )
            h = e.hash

            e['key'] = 'val2'

            h.should_not == e.hash

            e['key'].should == e.auditable['key']
            e['key'].should == 'val2'
        end
    end

    describe '#orig' do
        it 'should be frozen' do
            orig_auditable = @orig.auditable.dup
            is_frozen = false
            begin
                @orig.orig['ff'] = 'ffss'
            rescue RuntimeError
                is_frozen = true
            end
            is_frozen.should be_true
            @orig.orig.should == orig_auditable
        end
        context 'when auditable' do
            context 'has been modified' do
                it 'returns original input name/vals' do
                    orig_auditable = @orig.auditable.dup
                    @orig.auditable = {}
                    @orig.orig.should == orig_auditable
                    @orig.auditable = orig_auditable.dup
                end
            end
            context 'has not been modified' do
                it 'returns #auditable' do
                    @orig.orig.should == @orig.auditable
                end
            end
        end
        it 'aliased to #original' do
            @orig.orig.should == @orig.original
        end
    end

    describe '#reset' do
        it 'returns the auditable inputs to their original state' do
            orig = @orig.auditable.dup
            @orig.update( orig.keys.first => 'value' )
            (@orig.auditable != orig).should be_true
            @orig.reset
            @orig.auditable.should == orig
        end
    end

    describe '#remove_auditor' do
        it 'removes the auditor' do
            @orig.auditor = :some_auditor
            @orig.auditor.should == :some_auditor
            @orig.remove_auditor
            @orig.auditor.should be_nil
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
            @auditable.auditable.should == submitted
        end

        context 'when it has no auditor' do
            it 'falls back to using the anonymous auditor' do
                submitted = nil

                elem = auditable.new( @url + '/submit', 'param' => 'val' )
                elem.auditor.should be_nil

                elem.submit do |res|
                    submitted = load( res.body )
                end
                elem.auditor.should be_true

                elem.http.run

                elem.auditable.should == submitted
            end
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
                                      format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                        injected = element.opts[:injected_orig]
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
                                      format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                        injected << element.opts[:injected_orig]
                    end

                    @auditor.http.run
                    injected.uniq.sort.should == payloads.sort
                end

                context 'and is empty' do
                    it 'returns nil' do
                        injected = []
                        @auditable.audit( [],
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                            injected << element.opts[:injected_orig]
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
                                      format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                        injected << element.opts[:injected_orig]
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
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                            injected << element.opts[:injected_orig]
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
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                            injected << element.opts[:injected_orig]
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
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                            injected << element.opts[:injected_orig]
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
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |_, _, element|
                            injected << element.opts[:injected_orig]
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
                                      skip_orig: true,
                                      format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |res, opts|
                        submitted = load( res.body )
                    end

                    @auditor.http.run
                    cnt.should == 1
                    @auditable.auditable == submitted
                end

                it 'is able to modify mutations on the fly' do
                    submitted = nil

                    modified_seed = 'houa!'
                    each_mutation = proc do |mutation|
                        mutation.altered_value = modified_seed
                    end

                    @auditable.audit( @seed, each_mutation: each_mutation,
                                      skip_orig: true,
                                      format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |res, opts|
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
                            m.altered_value = 'houa!'

                            c = mutation.dup
                            c.altered_value = 'houa2!'

                            [m, c]
                        end

                        @auditable.audit( @seed, each_mutation: each_mutation,
                                          skip_orig: true,
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |res, opts|
                            injected << load( res.body ).values.first
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 3
                        injected.sort.should == [ @seed, 'houa!', 'houa2!'].sort
                    end
                end

            end

            describe :format do

                describe 'Arachni::Module::Auditor::Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        injected = nil
                        cnt = 0

                        @auditable.audit( @seed,
                                          skip_orig: true,
                                          format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ) do |res, opts|
                            injected = load( res.body )[opts[:altered]]
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @seed
                    end
                end

                describe 'Arachni::Module::Auditor::Format::APPEND' do
                    it 'appends the seed to the existing value of the input' do
                        injected = nil
                        cnt = 0

                        @auditable.audit( @seed,
                                          skip_orig: true,
                                          format: [ Arachni::Module::Auditor::Format::APPEND ] ) do |res, opts|
                            injected = load( res.body )[opts[:altered]]
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @default_input_value + @seed
                    end
                end

                describe 'Arachni::Module::Auditor::Format::NULL' do
                    it 'terminates the seed with a null character',
                       if: described_class != Arachni::Element::Header  do

                        injected = nil
                        cnt = 0
                        @auditable.audit( @seed,
                                          skip_orig: true,
                                          format: [ Arachni::Module::Auditor::Format::NULL ] ) do |res, opts|
                            injected = load( res.body )[opts[:altered]]
                            cnt += 1
                        end

                        @auditor.http.run
                        cnt.should == 1
                        auditable.decode( injected ).should == @seed + "\0"
                    end
                end

                describe 'Arachni::Module::Auditor::Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        injected = nil
                        cnt = 0

                        format = [ Arachni::Module::Auditor::Format::SEMICOLON ]
                        @auditable.audit( @seed, skip_orig: true, format: format ) do |res, opts|
                            injected = load( res.body )[opts[:altered]]
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
                        format: [ Arachni::Module::Auditor::Format::STRAIGHT ],
                        skip_orig: true
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

            describe :async do

                context true do
                    it 'performs all HTTP requests asynchronously' do
                        before = Time.now
                        @sleep.audit( @seed, async: true ){}
                        @auditor.http.run

                        # should take as long as the longest request
                        # and since we're doing this locally the longest
                        # request must take less than a second.
                        #
                        # so it should be 2 when converted into an Int
                        (Time.now - before).to_i.should == 2
                    end
                end

                context false do
                    it 'performs all HTTP requests synchronously' do
                        before = Time.now
                        @sleep.audit( @seed, async: false ){}
                        @auditor.http.run

                        (Time.now - before).should > 4.0
                    end
                end

                context 'default' do
                    it 'performs all HTTP requests asynchronously' do
                        before = Time.now
                        @sleep.audit( @seed ){}
                        @auditor.http.run

                        (Time.now - before).to_i.should == 2
                    end
                end

            end
        end

        context 'when the exclude_vectors option is set' do
            it 'skips those vectors by name' do
                e = auditable.new( @url + '/submit', 'include_this' => 'param', 'exclude_this' => 'param' )

                Arachni::Options.exclude_vectors << 'exclude_this'
                Arachni::Options.exclude_vectors << Arachni::Element::Form::ORIGINAL_VALUES

                audited = []
                e.audit( @seed ) { |_, _, elem| audited << elem.altered  }.should be_true
                e.http.run

                audited.uniq.should == %w(include_this)
            end
        end
        context 'when called with no opts' do
            it 'uses the defaults' do
                cnt = 0
                @auditable.audit( @seed ) { cnt += 1 }
                @auditor.http.run
                cnt.should == 4
            end
        end

        context 'when it has no auditor' do
            it 'falls back to using the anonymous auditor' do
                elem = auditable.new( @url, 'param' => 'val' )
                elem.auditor.should be_nil

                elem.taint_analysis( 'test' )
                elem.auditor.should be_true
                elem.http.run

                elem.auditor.issues.size.should == 1
                elem.auditor.raw_issues.size.should == 1
                issue = elem.auditor.raw_issues.first
                issue.elem.should == elem.type
                issue.id.should == 'test'
                issue.method.to_s.downcase.should == 'get'
                issue.name.should == 'Anonymous auditor'
                issue.var.should == 'param'

                elem.auditor.raw_issues.should == Arachni::Module::Manager.results
                elem.auditor.issues.should == elem.auditor.auditstore.issues
                elem.auditor.auditstore.should == Arachni::AuditStore.new(
                    options: Arachni::Options.instance.to_h,
                    issues: issues )
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
                e = auditable.new( @url + '/submit' )

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
