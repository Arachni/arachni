require 'spec_helper'
require 'tempfile'

describe Arachni::Support::Crypto::RSA_AES_CBC do

    SEED = 'seed data'

    before :all do
        private_key_file = Tempfile.new( 'private_key.pem' )
        private_key = OpenSSL::PKey::RSA.generate( 1024 )
        private_key_file.write( private_key.to_pem )
        private_key_file.close

        public_key  = private_key.public_key
        public_key_file = Tempfile.new( 'public_key.pem' )
        public_key_file.write( public_key.to_pem )
        public_key_file.close

        @private_key_file_path = private_key_file.path
        @public_key_file_path = public_key_file.path

        @crypto = described_class.new( @public_key_file_path, @private_key_file_path )
    end

    it 'generates matching encrypted and decrypted data' do
        expect(@crypto.decrypt( @crypto.encrypt( SEED ) )).to eq(SEED)
    end

end
