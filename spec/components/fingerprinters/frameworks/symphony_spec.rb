require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Symfony do
    include_examples 'fingerprinter'

    def platforms
        [:php, :symfony]
    end

    context 'when there is a symfony cookie' do
        it 'identifies it as Symfony' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { 'symfony' => 'stuff' } )]

            )
        end
    end

end
