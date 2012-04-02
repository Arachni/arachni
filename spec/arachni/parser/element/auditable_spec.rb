require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Auditable do

    before :all do
        @url     = server_url_for( :auditable )
        @auditor = Auditor.new( Arachni::HTTP.instance )

        @auditable = Arachni::Parser::Element::Link.new( @url, inputs: {'param' => 'val'} )
        @auditable.auditor = @auditor

        @orphan = Arachni::Parser::Element::Link.new( @url, inputs: { 'key' => 'val' } )

        # will sleep 2 secs before each response
        @sleep = Arachni::Parser::Element::Link.new( @url + '/sleep', inputs: {'param' => 'val'} )
        @sleep.auditor = @auditor

        @orig = Arachni::Parser::Element::Link.new( @url, inputs: { 'param' => 'val'} )

        @seed = 'my_seed'
        @default_input_value = @auditable.auditable['param']
    end

    describe :orig do
        it 'should be the same as auditable' do
            @orig.orig.should == @orig.auditable
        end
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
        context 'when auditable has been modified' do
            it 'should return original input name/vals' do
                orig_auditable = @orig.auditable.dup
                @orig.auditable = {}
                @orig.orig.should == orig_auditable
                @orig.auditable = orig_auditable.dup
            end
        end
    end

    describe :reset! do
        it 'should return the auditable inputs to their original state' do
            orig = @orig.auditable.dup
            @orig.auditable['new'] = 'value'
            (@orig.auditable != orig).should be_true
            @orig.reset!
            @orig.auditable.should == orig
        end
    end

    describe :orphan? do
        context 'when it has no auditor' do
            it 'should return true' do
                @orphan.orphan?.should be_true
            end
        end
        context 'when it has an auditor' do
            it 'should return true' do
                @auditable.orphan?.should be_false
            end
        end
    end

    describe :submit do
        it 'should submit the element along with its auditable inputs' do
            got_response = false
            has_submited_inputs = false

            @auditable.submit( remove_id: true ).on_complete {
                |res|
                got_response = true

                body_should = res.request.params.map { |k, v| k.to_s + v.to_s }.join( "\n" )
                has_submited_inputs = (res.body == body_should)
            }
            @auditor.http.run
            got_response.should be_true
            has_submited_inputs.should be_true
        end

        context 'when it has no auditor' do
            it 'should revert to the HTTP interface singleton' do
                got_response = false
                has_submited_inputs = false

                @orphan.submit( remove_id: true ).on_complete {
                    |res|
                    got_response = true

                    body_should = res.request.params.map { |k, v| k.to_s + v.to_s }.join( "\n" )
                    has_submited_inputs = (res.body == body_should)
                }
                @orphan.http.run
                got_response.should be_true
                has_submited_inputs.should be_true
            end
        end
    end

    describe :audit do

        before { Arachni::Parser::Element::Auditable.reset! }

        context 'when called with no opts' do
            it 'should use the defaults' do
                cnt = 0
                @auditable.audit( @seed ) {
                    cnt += 1
                }
                @auditor.http.run
                cnt.should == 4
            end
        end

        context 'when it has no auditor' do
            it 'should revert to the HTTP interface singleton' do
                cnt = 0
                @orphan.audit( @seed ) {
                    cnt += 1
                }
                @orphan.http.run
                cnt.should == 4
            end
        end

        describe :restrict_to_elements! do
            after { Arachni::Parser::Element::Auditable.reset_instance_scope! }

            context 'when set' do
                it 'should restrict the audit to the provided elements' do
                    scope_id_arr = [ @auditable.scope_audit_id ]
                    Arachni::Parser::Element::Auditable.restrict_to_elements!( scope_id_arr )
                    performed = false
                    @sleep.audit( '' ){ performed = true }
                    @sleep.http.run
                    performed.should be_false

                    performed = false
                    @auditable.audit( '' ){ performed = true }
                    @auditable.http.run
                    performed.should be_true
                end

                describe :override_instance_scope! do

                    after { @sleep.reset_scope_override! }

                    context 'when called' do
                        it 'should override scope restrictions' do
                            scope_id_arr = [ @auditable.scope_audit_id ]
                            Arachni::Parser::Element::Auditable.restrict_to_elements!( scope_id_arr )
                            performed = false
                            @sleep.audit( '' ){ performed = true }
                            @sleep.http.run
                            performed.should be_false

                            @sleep.override_instance_scope!
                            performed = false
                            @sleep.audit( '' ){ performed = true }
                            @sleep.http.run
                            performed.should be_true
                        end

                        describe :override_instance_scope? do
                            it 'should return true' do
                                @sleep.override_instance_scope!
                                @sleep.override_instance_scope?.should be_true
                            end
                        end
                    end

                    context 'when not called' do
                        describe :override_instance_scope? do
                            it 'should return false' do
                                @sleep.override_instance_scope?.should be_false
                            end
                        end
                    end
                end
            end

            context 'when not set' do
                it 'should not impose audit restrictions' do
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

        context 'when called with option' do

            describe :format do

                describe 'Arachni::Module::Auditor::Format::STRAIGHT' do
                    it 'should inject the seed as is' do
                        injected = nil
                        cnt = 0
                        @auditable.audit( @seed,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ] ){
                            |res, opts|
                            injected = res.request.params[opts[:altered]]
                            cnt = +1
                        }
                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @seed
                    end
                end

                describe 'Arachni::Module::Auditor::Format::APPEND' do
                    it 'should append the seed to the existing value of the input' do
                        injected = nil
                        cnt = 0
                        @auditable.audit( @seed,
                            format: [ Arachni::Module::Auditor::Format::APPEND ] ){
                            |res, opts|
                            injected = res.request.params[opts[:altered]]
                            cnt = +1
                        }
                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @default_input_value + @seed
                    end
                end

                describe 'Arachni::Module::Auditor::Format::NULL' do
                    it 'should terminate the seed with a null character' do
                        injected = nil
                        cnt = 0
                        @auditable.audit( @seed,
                            format: [ Arachni::Module::Auditor::Format::NULL ] ){
                            |res, opts|
                            injected = res.request.params[opts[:altered]]
                            cnt = +1
                        }
                        @auditor.http.run
                        cnt.should == 1
                        injected.should == @seed + "\0"
                    end
                end

                describe 'Arachni::Module::Auditor::Format::SEMICOLON' do
                    it 'should prepend the seed with a semicolon' do
                        injected = nil
                        cnt = 0
                        @auditable.audit( @seed,
                            format: [ Arachni::Module::Auditor::Format::SEMICOLON ] ){
                            |res, opts|
                            injected = res.request.params[opts[:altered]]
                            cnt = +1
                        }
                        @auditor.http.run
                        cnt.should == 1
                        injected.should == ";" + @seed
                    end
                end
            end

            describe :redundant do
                before do
                    @audit_opts = {
                        format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                    }
                end

                context true do
                    it 'should allow redundant audits' do
                        cnt = 0
                        5.times {
                            |i|
                            @auditable.audit( @seed, @audit_opts.merge( redundant: true )){
                                cnt += 1
                            }
                        }
                        @auditor.http.run
                        cnt.should == 5
                    end
                end

                context false do
                    it 'should not allow redundant requests/audits' do
                        cnt = 0
                        5.times {
                            |i|
                            @auditable.audit( @seed, @audit_opts.merge( redundant: false )){
                                cnt += 1
                            }
                        }
                        @auditor.http.run
                        cnt.should == 1
                    end
                end

                context 'default' do
                    it 'should not allow redundant requests/audits' do
                        cnt = 0
                        5.times {
                            |i|
                            @auditable.audit( @seed, @audit_opts ){
                                cnt += 1
                            }
                        }
                        @auditor.http.run
                        cnt.should == 1
                    end
                end
            end

            describe :async do

                context true do
                    it 'should perform all HTTP requests asynchronously' do
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
                    it 'should perform all HTTP requests synchronously' do
                        before = Time.now
                        @sleep.audit( @seed, async: false ){}
                        @auditor.http.run

                        (Time.now - before).should > 4.0
                    end
                end

                context 'default' do
                    it 'should perform all HTTP requests asynchronously' do
                        before = Time.now
                        @sleep.audit( @seed ){}
                        @auditor.http.run

                        (Time.now - before).to_i.should == 2
                    end
                end

            end
        end
    end
end
