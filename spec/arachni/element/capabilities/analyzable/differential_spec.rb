require 'spec_helper'

describe Arachni::Element::Capabilities::Analyzable::Differential do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :differential )
        @auditor = Auditor.new( Arachni::Page.from_url( @url ), Arachni::Framework.new )
    end

    after :each do
        @auditor.framework.reset
    end

    subject { Arachni::Element::Link.new( url: url, inputs: inputs ).tap { |e| e.auditor = auditor } }
    let(:auditor) { @auditor }
    let(:url) { @url }
    let(:inputs) { { 'input' => 'blah' } }

    describe '#dup' do
        context 'when #differential_analysis_options is' do
            context 'nil' do
                it 'skips #differential_analysis_options' do
                    subject.differential_analysis_options.should be_nil
                    dupped = subject.dup
                    dupped.should == dupped
                    dupped.differential_analysis_options.should be_nil
                end
            end

            context 'not nil' do
                it 'duplicates #differential_analysis_options' do
                    h = { stuff: 1 }

                    subject.differential_analysis_options = h

                    dupped = subject.dup
                    dupped.should == dupped
                    dupped.differential_analysis_options.should == h
                end
            end
        end
    end

    describe '#to_rpc_data' do
        it "does not include 'differential_analysis_options'" do
            subject.to_rpc_data.should_not include 'differential_analysis_options'
        end
    end

    describe '#differential_analysis' do
        before do
            @opts = {
                false:  'bad',
                pairs: [
                    { 'good' => 'bad' }
                ]
            }
        end

        context 'when the element action matches a skip rule' do
            let(:url) { 'http://stuff.com/' }

            it 'returns false' do
                subject.differential_analysis( @opts ).should be_false
            end
        end

        context 'when response behavior suggests a vuln' do
            let(:url) { @url + '/true' }

            it 'logs an issue' do
                subject.differential_analysis( @opts )
                auditor.http.run

                results = Arachni::Data.issues.flatten
                results.should be_any
                results.first.vector.affected_input_name.should == 'input'
            end

            it 'adds remarks' do
                subject.differential_analysis( @opts )
                auditor.http.run

                Arachni::Data.issues.first.variations.first.remarks[:differential_analysis].size.should == 3
            end
        end

        context "when responses aren't consistent with vulnerable behavior" do
            let(:url) { @url + '/false' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts )
                auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a request times out' do
            let(:url) { @url + '/timeout' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts.merge( submit: { timeout: 1_000 } ) )
                auditor.http.run

                issues.should be_empty

                Arachni::Element::Capabilities::Auditable.reset

                subject.differential_analysis( @opts.merge( timeout: 3_000 ) )
                auditor.http.run

                issues.should be_any
            end
        end

        context 'when a false response has an empty body' do
            let(:url) { @url + '/empty_false' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts )
                auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a true response has an empty body' do
            let(:url) { @url + '/empty_true' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts )
                auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a true response has non 200 status' do
            let(:url) { @url + '/non200_true' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts )
                auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a false response has non 200 status' do
            let(:url) { @url + '/non200_false' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts )
                auditor.http.run

                issues.should be_empty
            end
        end

        context 'when the control responses differ wildly' do
            let(:url) { @url + '/unstable' }

            it 'does not log any issues' do
                subject.differential_analysis( @opts )
                auditor.http.run

                issues.should be_empty
            end
        end

    end

end
