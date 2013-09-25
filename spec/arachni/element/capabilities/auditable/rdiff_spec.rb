require 'spec_helper'

describe Arachni::Element::Capabilities::Auditable::RDiff do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :rdiff )
        @auditor = Auditor.new( nil, Arachni::Framework.new )
    end

    describe '#rdiff_analysis' do
        before do
            @opts = {
                pairs: [
                    { 'good' => 'bad '}
                ]
            }
            @params = { 'rdiff' => 'blah' }

            Arachni::Element::Capabilities::Auditable.reset
            issues.clear
        end

        context 'when the element action matches a skip rule' do
            it 'returns false' do
                auditable = Arachni::Element::Link.new( 'http://stuff.com/', @params )
                auditable.rdiff_analysis( @opts ).should be_false
            end
        end

        context 'when response behavior suggests a vuln' do
            it 'logs an issue' do
                auditable = Arachni::Element::Link.new( @url + '/true', @params )
                auditable.auditor = @auditor
                auditable.rdiff_analysis( @opts )
                @auditor.http.run
                @auditor.http.run

                results = Arachni::Module::Manager.results
                results.should be_any
                results.first.var.should == 'rdiff'
            end
        end

        context 'when responses are\'t consistent with vuln behavior' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( @url + '/false', @params )
                auditable.auditor = @auditor
                auditable.rdiff_analysis( @opts )
                @auditor.http.run
                @auditor.http.run

                issues.should be_empty
            end
        end

        context 'when a request times out' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( @url + '/timeout', @params )
                auditable.auditor = @auditor
                auditable.rdiff_analysis( @opts.merge( timeout: 1_000 ) )
                @auditor.http.run
                @auditor.http.run

                issues.should be_empty

                Arachni::Element::Capabilities::Auditable.reset

                auditable = Arachni::Element::Link.new( @url + '/timeout', @params )
                auditable.auditor = @auditor
                auditable.rdiff_analysis( @opts.merge( timeout: 3_000 ) )
                @auditor.http.run
                @auditor.http.run

                issues.should be_any
            end
        end

        context 'when a response has an empty body' do
            it 'does not log any issues' do
                auditable = Arachni::Element::Link.new( @url + '/empty', @params )
                auditable.auditor = @auditor
                auditable.rdiff_analysis( @opts )
                @auditor.http.run
                @auditor.http.run

                issues.should be_empty
            end
        end
    end

end
