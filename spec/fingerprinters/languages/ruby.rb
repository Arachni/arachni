require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Ruby do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        described_class::IDs.each do |id|
            context "and it contains #{id}" do
                it 'identifies it as Ruby' do
                    page = Arachni::Page.new(
                        url:     'http://stuff.com/blah',
                        response_headers: { 'Server' => "Apache/2.2.21 (#{id})" }
                    )
                    platforms_for( page ).should include :ruby
                end
            end
        end
    end

    context 'when there is a X-Powered-By header' do
        described_class::IDs.each do |id|
            context "and it contains #{id}" do
                it 'identifies it as Ruby' do
                    page = Arachni::Page.new(
                        url:     'http://stuff.com/blah',
                        response_headers: { 'X-Powered-By' => "Apache/2.2.21 (#{id})" }
                    )
                    platforms_for( page ).should include :ruby
                end
            end
        end
    end

end
