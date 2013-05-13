require 'spec_helper'

describe Arachni::Support::Database::Hash do

    before :all do
        @hash = described_class.new
        @non_existent = 'blahblahblah'

        @seeds = {
            'key' => 'val',
            :key  => 'val2',
            { 'key' => 'val' } => 'val4'
        }
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-empty?
    it 'implements #empty?' do
        h = described_class.new

        h.empty?.should == {}.empty?

        nh = { :k => 'v' }
        h[:k] = 'v'

        h.empty?.should == nh.empty?
        h.clear
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-5B-5D-3D
    it 'implements #[]=( k, v ) (and store( k, v ))' do
        @seeds.each do |k, v|
            (@hash[k] = v).should == v
        end
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-5B-5D
    it 'implements #[]' do
        @seeds.each do |k, v|
            @hash[k].should == v
        end

        @hash[@non_existent].should == @seeds[@non_existent]
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-assoc
    it 'implements #assoc( k )' do
        @seeds.each do |k, v|
            @hash.assoc( k ).should == @seeds.assoc( k )
        end

        @hash.assoc( @non_existent ).should == @seeds.assoc( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-rassoc
    it 'implements #rassoc( k )' do
        @seeds.each do |k, v|
            @hash.rassoc( v ).should == @seeds.rassoc( v )
        end

        @hash.rassoc( @non_existent ).should == @seeds.rassoc( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-delete
    it 'implements #delete( k, &block )' do
        @hash.delete( @non_existent ).should == @seeds.delete( @non_existent )
        @seeds[@non_existent] = @hash[@non_existent] = 'foo'
        @hash.delete( @non_existent ).should == @seeds.delete( @non_existent )

        @hash.delete( @non_existent ) { |k| k }.should ==
            @seeds.delete( @non_existent ) { |k| k }
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-shift
    it 'implements #shift' do
        @hash.shift.should == @seeds.shift
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each
    it 'implements #each() (and #each_pair())' do
        @hash.each do |k, v|
            @seeds[k].should == v
        end

        # they must both return enumerators
        @hash.each.class.should == @seeds.each.class

        @hash.each_pair do |k, v|
            @seeds[k].should == v
        end

        # they must both return enumerators
        @hash.each_pair.class.should == @seeds.each_pair.class
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each_key
    it 'implements #each_key' do
        @hash.each_key do |k|
            @seeds[k].should == @hash[k]
        end

        # they must both return enumerators
        @hash.each_key.class.should == @seeds.each_key.class
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each_value
    it 'implements #each_value' do
        @hash.each_value do |v|
            @seeds[ @seeds.key( v )].should == v
        end

        # they must both return enumerators
        @hash.each_value.class.should == @seeds.each_value.class
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-keys
    it 'implements #keys' do
        @hash.keys.should == @seeds.keys
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-key
    it 'implement #key' do
        @hash.each_key do |k|
            @seeds.key( k ).should == @hash.key( k )
        end

        @hash.key( @non_existent ).should == @seeds.key( @non_existent )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-values
    it 'implements #values' do
        @hash.values.should == @seeds.values
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-include?
    it 'implements #include? (and #member?, #key?, #has_key?)' do
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
    it 'implements #merge' do
        mh = { :another_key => 'another value' }

        nh = @hash.merge( mh )
        nh.keys.should == @seeds.merge( mh ).keys
        nh.values.should == @seeds.merge( mh ).values
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-merge!
    it 'implements #merge! (and #update)' do
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
    it 'implements #to_hash' do
        @hash.to_hash.should == @seeds.to_hash
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-to_a
    it 'implements #to_a' do
        @hash.to_a.should == @seeds.to_a
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-size
    it 'implements #size' do
        @hash.size.should == @seeds.size
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-3D-3D
    it 'implements #== (and #eql?)' do
        (@hash == @hash.merge( {} )).should == true
        (@hash == @seeds).should == true
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-clear
    it 'implements #clear' do
        @hash.clear
        @seeds.clear
        @hash.size.should == @seeds.size
    end

    after :all do
        # clear the DB files
        @hash.clear
    end

end
