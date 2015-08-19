require 'spec_helper'

describe Arachni::Framework::Parts::Report do
    include_examples 'framework'

    describe '#reporters' do
        it 'provides access to the reporter manager' do
            expect(subject.reporters.is_a?( Arachni::Reporter::Manager )).to be_truthy
            expect(subject.reporters.available.sort).to eq(%w(afr foo error).sort)
        end
    end

    describe '#list_reporters' do
        it 'returns info on all reporters' do
            expect(subject.list_reporters.size).to eq(subject.reporters.available.size)

            info   = subject.list_reporters.find { |p| p[:options].any? }
            report = subject.reporters[info[:shortname]]

            report.info.each do |k, v|
                if k == :author
                    expect(info[k]).to eq([v].flatten)
                    next
                end

                expect(info[k]).to eq(v)
            end

            expect(info[:shortname]).to eq(report.shortname)
        end

        context 'when a pattern is given' do
            it 'uses it to filter out reporters that do not match it' do
                subject.list_reporters( 'foo' ).size == 1
                subject.list_reporters( 'boo' ).size == 0
            end
        end
    end

    describe '#report_as' do
        before( :each ) do
            reset_options
            @new_framework = Arachni::Framework.new
        end

        context 'when passed a valid reporter name' do
            it 'returns the reporter as a string' do
                json = @new_framework.report_as( :json )
                expect(JSON.load( json )['issues'].size).to eq(@new_framework.report.issues.size)
            end

            context 'which does not support the \'outfile\' option' do
                it 'raises Arachni::Component::Options::Error::Invalid' do
                    expect { @new_framework.report_as( :stdout ) }.to raise_error Arachni::Component::Options::Error::Invalid
                end
            end
        end

        context 'when passed an invalid reporter name' do
            it 'raises Arachni::Component::Error::NotFound' do
                expect { @new_framework.report_as( :blah ) }.to raise_error Arachni::Component::Error::NotFound
            end
        end
    end

end
