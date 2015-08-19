require 'spec_helper'

describe Arachni::Element::Path do
    it_should_behave_like 'element'
    it_should_behave_like 'with_auditor'

    let( :response ) do
        Arachni::HTTP::Response.new(
            request: Arachni::HTTP::Request.new(
                         url:    'http://a-url.com/',
                         method: :get,
                         headers: {
                             'req-header-name' => 'req header value'
                         }
                     ),

            code:    200,
            url:     'http://a-url.com/?myvar=my%20value',
            headers: {},
            dom:     {
                transitions: [ page: :load ]
            }
        )
    end

    subject { described_class.new response.url }

    describe '#action' do
        it 'delegates to #url' do
            expect(subject.action).to eq(subject.url)
        end
    end
end
