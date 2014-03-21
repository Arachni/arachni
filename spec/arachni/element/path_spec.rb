require 'spec_helper'

describe Arachni::Element::Path do
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

    subject { described_class.new response }

    describe '#to_h' do
        it 'returns a hash' do
            subject.to_h.should == {
                type: :path,
                url:  'http://a-url.com/?myvar=my%20value'
            }
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            path = subject.dup
            path.should == subject
            path.object_id.should_not == subject
        end
    end
end
