require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::Options do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret!'

        @get_instance = proc do |opts|
            opts ||= @opts
            port = random_port
            opts.rpc_port = port
            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1
            Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{port}", @token
            )
        end

        @utils = Arachni::Module::Utilities

        @instance = @get_instance.call
    end

    describe '#set' do
        context 'when keys are strings' do
            it 'should set options by hash' do
                opts = {
                    'url'       => 'http://blah.com',
                    'exclude'   => [ 'exclude me' ],
                    'include'   => [ 'include me' ],
                    'redundant' => { 'regexp' => 'redundant', 'count' => 3 },
                    'datastore' => { key: 'val' }
                }
                @instance.opts.set( opts )

                @instance.opts.url.to_s.should == @utils.normalize_url( opts['url'] )
                @instance.opts.exclude.should == [/exclude me/]
                @instance.opts.include.should == [/include me/]
                @instance.opts.datastore.should == opts['datastore']
            end
        end

        context 'when keys are symbols' do
            it 'should set options by hash' do
                opts = {
                    url:       'http://blah2.com',
                    exclude:   ['exclude me2'],
                    include:   ['include me2'],
                    redundant: { 'regexp' => 'redundant2', 'count' => 4 },
                    datastore: { key2: 'val2' }
                }
                @instance.opts.set( opts )

                @instance.opts.url.to_s.should == @utils.normalize_url( opts[:url] )
                @instance.opts.exclude.should == [/exclude me2/]
                @instance.opts.include.should == [/include me2/]
                @instance.opts.datastore.should == opts[:datastore]
            end
        end
    end

    describe '#exclude' do
        context 'when passed an array of strings' do
            it 'should set exclusion regexps' do
                regexp = 'exclude'
                @instance.opts.exclude = [regexp]
                @instance.opts.exclude.should == [/exclude/]
            end
        end

        context 'when passed an array of regular expressions' do
            it 'should set exclusion regexps' do
                regexp = /exclude this/
                @instance.opts.exclude = [regexp]
                @instance.opts.exclude.should == [/exclude this/]
            end
        end
    end

    describe '#include' do
        context 'when passed an array of strings' do
            it 'should set exclusion regexps' do
                regexp = 'include'
                @instance.opts.include = [regexp]
                @instance.opts.include.should == [/include/]
            end
        end

        context 'when passed an array of regular expressions' do
            it 'should set exclusion regexps' do
                regexp = /include this/
                @instance.opts.include = [regexp]
                @instance.opts.include.should == [/include this/]
            end
        end
    end

    describe '#redundant' do
        context 'when passed an array of strings' do
            it 'should set exclusion regexps' do
                regexp = {
                    'regexp' => 'this is redundant',
                    'count'  => '3'
                }
                @instance.opts.redundant = [regexp]
                @instance.opts.redundant.should == { /this is redundant/ => 3 }
            end
        end

        context 'when passed an array of regular expressions' do
            it 'should set exclusion regexps' do
                regexp = {
                    'regexp' => /this is redundant/,
                    'count'  => 5
                }
                @instance.opts.redundant = [regexp]
                @instance.opts.redundant.should == { /this is redundant/ => 5 }
            end
        end
    end
end
