require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Auditable do

    before :all do
        @url     = server_url_for( :auditable )
        @auditor = Auditor.new( Arachni::HTTP.instance )

        @auditable = Arachni::Parser::Element::Link.new( @url, inputs: {'param' => 'val'} )
        @auditable.auditor = @auditor

        # will sleep 2 secs before each response
        @sleep = Arachni::Parser::Element::Link.new( @url + '/sleep', inputs: {'param' => 'val'} )
        @sleep.auditor = @auditor

        @seed = 'my_seed'
        @default_input_value = @auditable.auditable['param']
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
    end

    describe :audit do

        before do
            Arachni::Parser::Element::Auditable.reset!
         end

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
