require 'spec_helper'

describe Arachni::Platform::Fingerprinters::CakePHP do
    include_examples 'fingerprinter'

    def platforms
        [:php, :cakephp]
    end

    context 'when there is a CAKEPHP cookie' do
        it 'identifies it as CakePHP' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url: 'http://stuff.com/blah',
                              inputs: { 'CAKEPHP' => 'stuff' } )]

            )
        end
    end

end
