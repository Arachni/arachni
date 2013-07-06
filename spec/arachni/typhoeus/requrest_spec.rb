require 'spec_helper'

describe Typhoeus::Request do

    describe '#id' do
        it 'is accessible' do
            req = Typhoeus::Request.new( '' )
            req.id = 1
            req.id.should == 1
        end
    end

    describe '#on_complete' do
        context 'when multi is enabled' do
            it 'allows multiple callbacks' do
                req = Typhoeus::Request.new( '' )

                a = []
                req.on_complete( true ) { a << 1 }
                req.on_complete( true ) { a << 2 }
                req.on_complete{ a << 3 }

                req.call_handlers
                a.should == [1, 2, 3]
            end
        end

        it 'sets a single callback to handle the response' do
            req = Typhoeus::Request.new( '' )

            a = []
            req.on_complete { a << 1 }
            req.on_complete { a << 2 }

            req.call_handlers
            a.should == [2]
        end
    end

    describe '#train' do
        it 'sets train? to return true' do
            req = Typhoeus::Request.new( '' )
            req.train?.should be_false
            req.train
            req.train?.should be_true
        end
    end

    describe '#update_cookies' do
        it 'sets update_cookies? to return true' do
            req = Typhoeus::Request.new( '' )
            req.update_cookies?.should be_false
            req.update_cookies
            req.update_cookies?.should be_true
        end
    end

end
