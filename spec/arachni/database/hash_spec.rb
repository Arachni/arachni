require_relative '../../spec_helper'
require_testee

describe Arachni::Database::Hash do

    before :all do
        @hash = Arachni::Database::Hash.new
        @non_existent = 'blahblahblah'

        @seeds = {
            'key' => 'val',
            :key  => 'val2',
            { 'key' => 'val' } => 'val4'
        }
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-empty?
    it 'should implement empty?()' do
        h = Arachni::Database::Hash.new

        h.empty?.should == {}.empty?

        nh = { :k => 'v' }
        h[:k] = 'v'

        h.empty?.should == nh.empty?
        h.clear
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-5B-5D-3D
    it 'should implement #[]=( k, v ) (and store( k, v ))' do
        @seeds.each {
            |k, v|
            ( @hash[k] = v ).should == v
        }
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-5B-5D
    it 'should implement #[]' do
        @seeds.each {
            |k, v|
            @hash[k].should == v
        }

        @hash[@non_existent].should == @seeds[@non_existent]
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-assoc
    it 'should implement assoc( k )' do
        @seeds.each {
            |k, v|
            @hash.assoc( k ).should == @seeds.assoc( k )
        }

        @hash.assoc( @non_existent ).should == @seeds.assoc( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-rassoc
    it 'should implement rassoc( k )' do
        @seeds.each {
            |k, v|
            @hash.rassoc( v ).should == @seeds.rassoc( v )
        }

        @hash.rassoc( @non_existent ).should == @seeds.rassoc( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-delete
    it 'should implement delete( k, &block )' do
        @hash.delete( @non_existent ).should == @seeds.delete( @non_existent )
        @seeds[@non_existent] = @hash[@non_existent] = 'foo'
        @hash.delete( @non_existent ).should == @seeds.delete( @non_existent )

        @hash.delete( @non_existent ) { |k| k }.should ==
            @seeds.delete( @non_existent ) { |k| k }
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-shift
    it 'should implement shift()' do
        @hash.shift.should == @seeds.shift
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each
    it 'should implement each() (and each_pair())' do
        @hash.each {
            |k, v|
            @seeds[k].should == v
        }

        # they muct both return enumerators
        @hash.each.class.should == @seeds.each.class

        @hash.each_pair {
            |k, v|
            @seeds[k].should == v
        }

        # they muct both return enumerators
        @hash.each_pair.class.should == @seeds.each_pair.class
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each_key
    it 'should implement each_key()' do
        @hash.each_key {
            |k|
            @seeds[k].should == @hash[k]
        }

        # they muct both return enumerators
        @hash.each_key.class.should == @seeds.each_key.class
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each_value
    it 'should implement each_value()' do
        @hash.each_value {
            |v|
            @seeds[ @seeds.key( v )].should == v
        }

        # they muct both return enumerators
        @hash.each_value.class.should == @seeds.each_value.class
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-keys
    it 'should implement keys()' do
        @hash.keys.should == @seeds.keys
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-key
    it 'should implement key()' do
        @hash.each_key {
            |k|
            @seeds.key( k ).should == @hash.key( k )
        }

        @hash.key( @non_existent ).should == @seeds.key( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-values
    it 'should implement values()' do
        @hash.values.should == @seeds.values
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-include?
    it 'should implement include?() (and member?(), key?(), has_key?())' do
        @hash.each_key {
            |k|
            @seeds.include?( k ).should == @hash.include?( k )
            @seeds.member?( k ).should == @hash.member?( k )
            @seeds.key?( k ).should == @hash.key?( k )
            @seeds.has_key?( k ).should == @hash.has_key?( k )
        }

        @hash.include?( @non_existent ).should == @seeds.include?( @non_existent )
        @hash.member?( @non_existent ).should == @seeds.member?( @non_existent )
        @hash.key?( @non_existent ).should == @seeds.key?( @non_existent )
        @hash.has_key?( @non_existent ).should == @seeds.has_key?( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-merge
    it 'should implement merge()' do
        mh = { :another_key => 'another value' }

        nh = @hash.merge( mh )
        nh.keys.should == @seeds.merge( mh ).keys
        nh.values.should == @seeds.merge( mh ).values
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-merge!
    it 'should implement merge!() (and update())' do
        mh = { :another_other_key => 'another other value' }
        mh2 = { :another_other_key2 => 'another other value2' }

        @hash.merge!( mh )
        @seeds.merge!( mh )

        @hash.update( mh2 )
        @seeds.update( mh2 )

        @hash.keys.should == @seeds.keys
        @hash.values.should == @seeds.values
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-to_hash
    it 'should implement to_hash()' do
        @hash.to_hash.should == @seeds.to_hash
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-to_a
    it 'should implement to_a()' do
        @hash.to_a.should == @seeds.to_a
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-size
    it 'should implement size()' do
        @hash.size.should == @seeds.size
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-3D-3D
    it 'should implement ==() (and eql?())' do
        (@hash == @hash.merge( {} )).should == true
        (@hash == @seeds).should == true
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-clear
    it 'should implement clear()' do
        @hash.clear
        @seeds.clear
        @hash.size.should == @seeds.size
    end

    after :all do
        # clear the DB files
        @hash.clear
    end

end
