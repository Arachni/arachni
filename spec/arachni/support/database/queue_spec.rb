require 'spec_helper'

describe Arachni::Support::Database::Queue do

    before :all do
        @seeds = [
            'val',
            :val,
            { 'val' => :val },
            [ 'val', :val ]
        ]

        @queue  = described_class.new
        @seed_q = Queue.new
    end

    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/thread/rdoc/Queue.html#method-i-empty-3F
    it 'implements #empty?' do
        @queue.empty?.should == @seed_q.empty?
    end

    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/thread/rdoc/Queue.html#method-i-3C-3C
    it 'implements #<<(v) (and #push(v), #enq(v))' do
        @queue  << @seeds[0].should == @seed_q << @seeds[0]
        @queue.push( @seeds[1] ).should == @seed_q.push( @seeds[1] )
        @queue.enq( @seeds[2] ).should == @seed_q.enq( @seeds[2] )
    end

    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/thread/rdoc/Queue.html#method-i-pop
    it 'implements #shift (and #pop, #deq)' do
        @queue.pop.should == @seed_q.pop
        @queue.shift.should == @seed_q.shift
        @queue.deq.should == @seed_q.deq
    end

    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/thread/rdoc/Queue.html#method-i-size
    it 'implements #size' do
        @queue.size.should == @seed_q.size
    end

    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/thread/rdoc/Queue.html#method-i-clear
    it 'implements #clear' do
        @queue.clear
        @seed_q.clear
        @queue.size.should == @seed_q.size
    end

    after :all do
        @queue.clear
    end
end
