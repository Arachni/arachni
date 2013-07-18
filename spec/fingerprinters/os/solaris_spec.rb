require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Solaris do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        described_class::IDs.each do |id|
            context "and it contains #{id}" do
                it 'identifies it as Solaris' do
                    page = Arachni::Page.from_data(
                        url:     'http://stuff.com/blah',
                        response: { headers: { 'Server' => "Apache/2.2.21 (#{id})" } }
                    )
                    platforms_for( page ).should include :solaris
                end
            end
        end
    end

    context 'when there is a X-Powered-By header' do
        described_class::IDs.each do |id|
            context "and it contains #{id}" do
                it 'identifies it as Solaris' do
                    page = Arachni::Page.from_data(
                        url:     'http://stuff.com/blah',
                        response: { headers: { 'X-Powered-By' => "Apache/2.2.21 (#{id})" } }
                    )
                    platforms_for( page ).should include :solaris
                end
            end
        end
    end

end
