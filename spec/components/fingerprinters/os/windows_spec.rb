require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Windows do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        described_class::IDs.each do |id|
            context "and it contains #{id}" do
                it 'identifies it as Windows' do
                    page = Arachni::Page.from_data(
                        url:     'http://stuff.com/blah',
                        response: { headers: { 'Server' => "Apache/2.2.21 (#{id})" } }
                    )
                    platforms_for( page ).should include :windows
                end
            end
        end
    end

    context 'when there is a X-Powered-By header' do
        described_class::IDs.each do |id|
            context "and it contains #{id}" do
                it 'identifies it as Windows' do
                    page = Arachni::Page.from_data(
                        url:     'http://stuff.com/blah',
                        response: { headers: { 'X-Powered-By' => "PHP/5.0 (#{id})" } }
                    )
                    platforms_for( page ).should include :windows
                end
            end
        end
    end

end
