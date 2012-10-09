require_relative '../../../../spec_helper'

describe Arachni::Element::Capabilities::Auditable::Taint do

    before :all do
        @url = server_url_for( :taint )
        @auditor = Auditor.new

        @positive = Arachni::Element::Link.new( @url, 'input' => '' )
        @positive.auditor = @auditor

        @negative = Arachni::Element::Link.new( @url, 'inexistent_input' => '' )
        @negative.auditor = @auditor
    end

    describe '.taint' do

        before do
            @seed = 'my_seed'
            Arachni::Framework.reset
         end

        context 'when called with no opts' do
            it 'should use the defaults' do
                @positive.taint_analysis( @seed )
                @auditor.http.run
                issues.size.should == 1
            end
        end

        context 'when called against non-vulnerable input' do
            it 'should not log issue' do
                @negative.taint_analysis( @seed )
                @auditor.http.run
                issues.should be_empty
            end
        end

        context 'when called with option' do

            context 'for matching with' do

                describe :regexp do
                    context 'with valid :match' do
                        it 'should verify the matched data with the provided string' do
                            @positive.taint_analysis( @seed,
                                regexp: /my_.+d/,
                                match: @seed,
                                format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                             )
                            @auditor.http.run
                            issues.size.should == 1
                            issues.first.injected.should == @seed
                        end
                    end

                    context 'with invalid :match' do
                        it 'should not log issue' do
                            @positive.taint_analysis( @seed,
                                regexp: @seed,
                                match: 'blah',
                                format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                             )
                            @auditor.http.run
                            issues.should be_empty
                        end
                    end

                    context 'without :match' do
                        it 'should try to match the provided pattern' do
                            @positive.taint_analysis( @seed,
                                regexp: @seed,
                                format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                             )
                            @auditor.http.run
                            issues.size.should == 1
                            issues.first.injected.should == @seed
                        end
                    end
                end

                describe :substring do
                    it 'should try to find the provided substring' do
                        @positive.taint_analysis( @seed,
                            substring: @seed,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                         )
                        @auditor.http.run
                        issues.size.should == 1
                    end
                end

                describe :ignore do
                    it 'should ignore matches whose response also matches them' do
                        @positive.taint_analysis( @seed,
                            substring: @seed,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ],
                            ignore: @seed
                        )
                        @auditor.http.run
                        issues.should be_empty
                    end
                end

            end
        end

    end

end
