require 'spec_helper'

require Arachni::Options.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.dir['lib'] + 'rpc/server/instance'

class Arachni::RPC::Server::Instance
    def cookies
        Arachni::HTTP::Client.cookies
    end
    def clear_cookies
        Arachni::Options.reset
        Arachni::HTTP::Client.cookie_jar.clear
        true
    end
end

describe Arachni::RPC::Server::ActiveOptions do
    before( :all ) do
        @utils = Arachni::Module::Utilities
        @instance = instance_spawn
    end

    before( :each ) { @instance.service.clear_cookies }

    describe '#set' do
        context 'when keys are strings' do
            it 'sets options by hash' do
                @instance.service.cookies.should be_empty

                opts = {
                    'url'           => 'http://blah.com',
                    'exclude'       => [ 'exclude me' ],
                    'include'       => [ 'include me' ],
                    'redundant'     => { 'regexp' => 'redundant', 'count' => 3 },
                    'datastore'     => { key: 'val' },
                    'cookies'       => { name: 'value' },
                    'cookie_string' => 'name3=value3'
                }
                @instance.opts.set( opts )

                @instance.opts.url.to_s.should == @utils.normalize_url( opts['url'] )
                @instance.opts.exclude.should == [/exclude me/]
                @instance.opts.include.should == [/include me/]
                @instance.opts.datastore.should == opts['datastore']

                @instance.service.cookies.should ==
                    [ Arachni::Cookie.new( opts['url'], opts['cookies'] ),
                      Arachni::Cookie.new( opts['url'], { name3: 'value3' } )]

                @instance.opts.cookies.should == @instance.service.cookies
            end
        end

        context 'when keys are symbols' do
            it 'sets options by hash' do
                @instance.service.cookies.should be_empty

                opts = {
                    url:            'http://blah2.com',
                    exclude:        ['exclude me2'],
                    include:        ['include me2'],
                    redundant:      { 'regexp' => 'redundant2', 'count' => 4 },
                    datastore:      { key2: 'val2' },
                    cookies:        { name: 'value' },
                    cookie_string: 'name3=value3'
                }
                @instance.opts.set( opts )

                @instance.opts.url.to_s.should == @utils.normalize_url( opts[:url] )
                @instance.opts.exclude.should == [/exclude me2/]
                @instance.opts.include.should == [/include me2/]
                @instance.opts.datastore.should == opts[:datastore]

                @instance.service.cookies.should ==
                    [ Arachni::Cookie.new( opts[:url], opts[:cookies] ),
                      Arachni::Cookie.new( opts[:url], { name3: 'value3' } )]

                @instance.opts.cookies.should == @instance.service.cookies
            end
        end
    end

    describe '#exclude=' do
        context 'when passed an array of strings' do
            it 'sets exclusion regexps' do
                regexp = 'exclude'
                @instance.opts.exclude = [regexp]
                @instance.opts.exclude.should == [/exclude/]
            end
        end

        context 'when passed an array of regular expressions' do
            it 'sets exclusion regexps' do
                regexp = /exclude this/
                @instance.opts.exclude = [regexp]
                @instance.opts.exclude.should == [/exclude this/]
            end
        end
    end

    describe '#include=' do
        context 'when passed an array of strings' do
            it 'sets exclusion regexps' do
                regexp = 'include'
                @instance.opts.include = [regexp]
                @instance.opts.include.should == [/include/]
            end
        end

        context 'when passed an array of regular expressions' do
            it 'sets exclusion regexps' do
                regexp = /include this/
                @instance.opts.include = [regexp]
                @instance.opts.include.should == [/include this/]
            end
        end
    end

    describe '#redundant=' do
        context 'when passed an array of strings' do
            it 'sets exclusion regexps' do
                regexp = {
                    'regexp' => 'this is redundant',
                    'count'  => '3'
                }
                @instance.opts.redundant = [regexp]
                @instance.opts.redundant.should == { /this is redundant/ => 3 }
            end
        end

        context 'when passed an array of regular expressions' do
            it 'sets exclusion regexps' do
                regexp = {
                    'regexp' => /this is redundant/,
                    'count'  => 5
                }
                @instance.opts.redundant = [regexp]
                @instance.opts.redundant.should == { /this is redundant/ => 5 }
            end
        end
    end

    describe '#cookies=' do
        context 'when passed a' do
            context Arachni::Cookie do
                it 'updates the cookie-jar' do
                    c = Arachni::Cookie.new( 'http://test.com', name: 'value' )

                    @instance.service.cookies.should be_empty

                    @instance.opts.cookies = c

                    cookies = @instance.service.cookies
                    cookies.first.name.should == 'name'
                    cookies.first.value.should == 'value'
                end
            end

            context Hash do
                it 'updates the cookie-jar' do
                    @instance.service.cookies.should be_empty

                    @instance.opts.url = 'http://test.com'
                    @instance.opts.cookies = { name: 'value' }

                    cookies = @instance.service.cookies
                    cookies.first.name.should == 'name'
                    cookies.first.value.should == 'value'
                end
            end

            context String do
                it 'updates the cookie-jar' do
                    @instance.service.cookies.should be_empty

                    @instance.opts.url = 'http://test.com'
                    @instance.opts.cookies = 'name=value'

                    cookies = @instance.service.cookies
                    cookies.first.name.should == 'name'
                    cookies.first.value.should == 'value'
                end
            end

            context Array do
                it 'updates the cookie-jar' do
                    @instance.service.cookies.should be_empty

                    @instance.opts.url = 'http://test.com'

                    @instance.opts.cookies = [
                        Arachni::Cookie.new( 'http://test.com', cookie_name: 'cookie_value' ),
                        { hash_name: 'hash_value' },
                        'string_name=string_value'
                    ]

                    cookies = @instance.service.cookies

                    cookies.size.should == 3

                    c = cookies.shift
                    c.name.should == 'cookie_name'
                    c.value.should == 'cookie_value'

                    c = cookies.shift
                    c.name.should == 'hash_name'
                    c.value.should == 'hash_value'

                    c = cookies.shift
                    c.name.should == 'string_name'
                    c.value.should == 'string_value'
                end
            end

        end
    end

    describe '#cookie_jar=' do
        context 'when passed a' do
            context Arachni::Cookie do
                it 'updates the cookie-jar' do
                    c = Arachni::Cookie.new( 'http://test.com', name: 'value' )

                    @instance.service.cookies.should be_empty

                    @instance.opts.cookie_jar = c

                    cookies = @instance.service.cookies
                    cookies.first.name.should == 'name'
                    cookies.first.value.should == 'value'
                end
            end

            context Hash do
                it 'updates the cookie-jar' do
                    @instance.service.cookies.should be_empty

                    @instance.opts.url = 'http://test.com'
                    @instance.opts.cookie_jar = { name: 'value' }

                    cookies = @instance.service.cookies
                    cookies.first.name.should == 'name'
                    cookies.first.value.should == 'value'
                end
            end

            context String do
                it 'updates the cookie-jar' do
                    @instance.service.cookies.should be_empty

                    @instance.opts.url = 'http://test.com'
                    @instance.opts.cookie_jar = 'name=value'

                    cookies = @instance.service.cookies
                    cookies.first.name.should == 'name'
                    cookies.first.value.should == 'value'
                end
            end

            context Array do
                it 'updates the cookie-jar' do
                    @instance.service.cookies.should be_empty

                    @instance.opts.url = 'http://test.com'
                    @instance.opts.cookie_jar = [
                        Arachni::Cookie.new( 'http://test.com', cookie_name: 'cookie_value' ),
                        { hash_name: 'hash_value' },
                        'string_name=string_value'
                    ]

                    cookies = @instance.service.cookies

                    cookies.size.should == 3

                    c = cookies.shift
                    c.name.should == 'cookie_name'
                    c.value.should == 'cookie_value'

                    c = cookies.shift
                    c.name.should == 'hash_name'
                    c.value.should == 'hash_value'

                    c = cookies.shift
                    c.name.should == 'string_name'
                    c.value.should == 'string_value'
                end
            end

        end
    end

    describe '#cookie_string=' do
        it 'updates the cookie-jar' do
            @instance.service.cookies.should be_empty

            @instance.opts.url = 'http://test.com'
            @instance.opts.cookie_string = 'name=value'

            cookies = @instance.service.cookies
            cookies.first.name.should == 'name'
            cookies.first.value.should == 'value'
        end
    end

    describe '#proxy=' do
        it 'updates the proxy settings' do
            @instance.opts.proxy = 'test.com:8080'

            @instance.opts.proxy_host.should == 'test.com'
            @instance.opts.proxy_port.should == 8080
        end
    end
end
