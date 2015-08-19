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

        expect(h.empty?).to eq({}.empty?)

        nh = { :k => 'v' }
        h[:k] = 'v'

        expect(h.empty?).to eq(nh.empty?)
        h.clear
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-5B-5D-3D
    it 'implements #[]=( k, v ) (and store( k, v ))' do
        @seeds.each do |k, v|
            expect(@hash[k] = v).to eq(v)
        end
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-5B-5D
    it 'implements #[]' do
        @seeds.each do |k, v|
            expect(@hash[k]).to eq(v)
        end

        expect(@hash[@non_existent]).to eq(@seeds[@non_existent])
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-assoc
    it 'implements #assoc( k )' do
        @seeds.each do |k, v|
            expect(@hash.assoc( k )).to eq(@seeds.assoc( k ))
        end

        expect(@hash.assoc( @non_existent )).to eq(@seeds.assoc( @non_existent ))
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-rassoc
    it 'implements #rassoc( k )' do
        @seeds.each do |k, v|
            expect(@hash.rassoc( v )).to eq(@seeds.rassoc( v ))
        end

        expect(@hash.rassoc( @non_existent )).to eq(@seeds.rassoc( @non_existent ))
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-delete
    it 'implements #delete( k, &block )' do
        expect(@hash.delete( @non_existent )).to eq(@seeds.delete( @non_existent ))
        @seeds[@non_existent] = @hash[@non_existent] = 'foo'
        expect(@hash.delete( @non_existent )).to eq(@seeds.delete( @non_existent ))

        expect(@hash.delete( @non_existent ) { |k| k }).to eq(
            @seeds.delete( @non_existent ) { |k| k }
        )
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-shift
    it 'implements #shift' do
        expect(@hash.shift).to eq(@seeds.shift)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each
    it 'implements #each() (and #each_pair())' do
        @hash.each do |k, v|
            expect(@seeds[k]).to eq(v)
        end

        # they must both return enumerators
        expect(@hash.each.class).to eq(@seeds.each.class)

        @hash.each_pair do |k, v|
            expect(@seeds[k]).to eq(v)
        end

        # they must both return enumerators
        expect(@hash.each_pair.class).to eq(@seeds.each_pair.class)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each_key
    it 'implements #each_key' do
        @hash.each_key do |k|
            expect(@seeds[k]).to eq(@hash[k])
        end

        # they must both return enumerators
        expect(@hash.each_key.class).to eq(@seeds.each_key.class)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-each_value
    it 'implements #each_value' do
        @hash.each_value do |v|
            expect(@seeds[ @seeds.key( v )]).to eq(v)
        end

        # they must both return enumerators
        expect(@hash.each_value.class).to eq(@seeds.each_value.class)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-keys
    it 'implements #keys' do
        expect(@hash.keys).to eq(@seeds.keys)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-key
    it 'implement #key' do
        @hash.each_key do |k|
            expect(@seeds.key( k )).to eq(@hash.key( k ))
        end

        expect(@hash.key( @non_existent )).to eq(@seeds.key( @non_existent ))
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-values
    it 'implements #values' do
        expect(@hash.values).to eq(@seeds.values)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-include?
    it 'implements #include? (and #member?, #key?, #has_key?)' do
        @hash.each_key {
            |k|
            expect(@seeds.include?( k )).to eq(@hash.include?( k ))
            expect(@seeds.member?( k )).to eq(@hash.member?( k ))
            expect(@seeds.key?( k )).to eq(@hash.key?( k ))
            expect(@seeds.has_key?( k )).to eq(@hash.has_key?( k ))
        }

        expect(@hash.include?( @non_existent )).to eq(@seeds.include?( @non_existent ))
        expect(@hash.member?( @non_existent )).to eq(@seeds.member?( @non_existent ))
        expect(@hash.key?( @non_existent )).to eq(@seeds.key?( @non_existent ))
        expect(@hash.has_key?( @non_existent )).to eq(@seeds.has_key?( @non_existent ))
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-merge
    it 'implements #merge' do
        mh = { :another_key => 'another value' }

        nh = @hash.merge( mh )
        expect(nh.keys).to eq(@seeds.merge( mh ).keys)
        expect(nh.values).to eq(@seeds.merge( mh ).values)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-merge!
    it 'implements #merge! (and #update)' do
        mh = { :another_other_key => 'another other value' }
        mh2 = { :another_other_key2 => 'another other value2' }

        @hash.merge!( mh )
        @seeds.merge!( mh )

        @hash.update( mh2 )
        @seeds.update( mh2 )

        expect(@hash.keys).to eq(@seeds.keys)
        expect(@hash.values).to eq(@seeds.values)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-to_hash
    it 'implements #to_hash' do
        expect(@hash.to_hash).to eq(@seeds.to_hash)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-to_a
    it 'implements #to_a' do
        expect(@hash.to_a).to eq(@seeds.to_a)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-size
    it 'implements #size' do
        expect(@hash.size).to eq(@seeds.size)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-3D-3D
    it 'implements #== (and #eql?)' do
        expect(@hash == @hash.merge( {} )).to eq(true)
        expect(@hash == @seeds).to eq(true)
    end

    # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-clear
    it 'implements #clear' do
        @hash.clear
        @seeds.clear
        expect(@hash.size).to eq(@seeds.size)
    end

    after :all do
        # clear the DB files
        @hash.clear
    end

end
