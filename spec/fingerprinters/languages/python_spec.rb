require 'spec_helper'

describe Arachni::Platforms::Fingerprinters::Python do
    include_examples 'fingerprinter'

    context 'when the page has a .py extension' do
        it 'identifies it as Python' do
            page = Arachni::Page.new( url: 'http://stuff.com/blah.py' )
            platforms_for( page ).should include :python
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as PHP' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                headers: [Arachni::Header.new( 'http://stuff.com/blah',
                                               'X-Powered-By' => 'Python/stuff' )]

            )
            platforms_for( page ).should include :python
        end
    end

end
