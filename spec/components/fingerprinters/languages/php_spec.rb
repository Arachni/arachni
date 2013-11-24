require 'spec_helper'

describe Arachni::Platform::Fingerprinters::PHP do
    include_examples 'fingerprinter'

    context 'when the page has a .php extension' do
        it 'identifies it as PHP' do
            page = Arachni::Page.from_data( url: 'http://stuff.com/blah.php' )
            platforms_for( page ).should include :php
        end
    end

    context 'when the page has a .php/ rewrite' do
        it 'identifies it as PHP' do
            page = Arachni::Page.from_data( url: 'http://stuff.com/blah.php/Stuff/1' )
            platforms_for( page ).should include :php
        end
    end

    context 'when the page has a .php5 (or similarly numbered) extension' do
        it 'identifies it as PHP' do
            page = Arachni::Page.from_data( url: 'http://stuff.com/blah.php5' )
            platforms_for( page ).should include :php
        end
    end

    context 'when there is a PHPSESSID query parameter' do
        it 'identifies it as PHP' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/blah?PHPSESSID=stuff'
            )
            platforms_for( page ).should include :php
        end
    end

    context 'when there is a PHPSESSID cookie' do
        it 'identifies it as PHP' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url: 'http://stuff.com/blah',
                              inputs: { 'PHPSESSID' => 'stuff' } )]

            )
            platforms_for( page ).should include :php
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as PHP' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'PHP/5.1.2' } }
            )
            platforms_for( page ).should include :php
        end
    end

end
