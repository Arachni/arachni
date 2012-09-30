require_relative '../../../../spec_helper'

describe Arachni::Element::Capabilities::Auditable::RDiff do

    before :all do
        @url     = server_url_for( :rdiff )
        @auditor = Auditor.new
    end

    describe '#rdiff_analysis' do
        before do
            @opts = {
                faults: ['bad'],
                bools:  ['good']
            }
            @params = { 'rdiff' => 'blah' }
            issues.clear
        end

        context 'when response behavior suggests a vuln' do
            it 'should log issue' do
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
            it 'should not log issue' do
                auditable = Arachni::Element::Link.new( @url + '/false', @params )
                auditable.auditor = @auditor
                auditable.rdiff_analysis( @opts )
                @auditor.http.run
                @auditor.http.run
                issues.should be_empty
            end
        end

    end

end
