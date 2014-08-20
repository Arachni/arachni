require 'spec_helper'

describe Arachni::Element::Capabilities::Analyzable::Differential do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :differential )
        @auditor = Auditor.new( Arachni::Page.from_url( @url ), Arachni::Framework.new )
    end

    after :each do
        @auditor.framework.reset
    end

    describe '#differential_analysis' do
        before do
            @opts = {
                false:  'bad',
                pairs: [
                    { 'good' => 'bad' }
                ]
            }

            @params = { 'input' => 'blah' }
        end

        context 'when the element action matches a skip rule' do
            it 'returns false' do
                auditable = Arachni::Element::Link.new( url: 'http://stuff.com/', inputs: @params )
                auditable.differential_analysis( @opts ).should be_false
            end
        end

        context 'when response behavior suggests a vuln' do
            it 'logs an issue' do
                auditable = Arachni::Element::Link.new( url: @url + '/true', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                results = Arachni::Data.issues.flatten
                results.should be_any
                results.first.vector.affected_input_name.should == 'input'
            end
        end

        context 'when responses are\'t consistent with vuln behavior' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/false', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a request times out' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/timeout', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts.merge( submit: { timeout: 1_000 } ) )
                @auditor.http.run

                issues.should be_empty

                Arachni::Element::Capabilities::Auditable.reset

                auditable = Arachni::Element::Link.new( url: @url + '/timeout', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts.merge( timeout: 3_000 ) )
                @auditor.http.run
                @auditor.http.run

                issues.should be_any
            end
        end

        context 'when a false response has an empty body' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/empty_false', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a true response has an empty body' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/empty_true', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a true response has non 200 status' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/non200_true', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a false response has non 200 status' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/non200_false', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                issues.should be_empty
            end
        end

        context 'when the control responses differ wildly' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( url: @url + '/unstable', inputs: @params )
                auditable.auditor = @auditor
                auditable.differential_analysis( @opts )
                @auditor.http.run

                issues.should be_empty
            end
        end

    end

end
