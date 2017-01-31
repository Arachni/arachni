=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'openssl'
require "base64"

module Arachni
module Support::Crypto

# Simple hybrid crypto class using RSA for public key encryption and AES with CBC
# for bulk data encryption/decryption.
#
# RSA is used to encrypt the AES primitives which are used to encrypt the plaintext.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class RSA_AES_CBC

    # If only encryption is required the private key parameter can be omitted.
    #
    # @param  [String]  public_pem
    #   Location of the Public key in PEM format.
    # @param  [String]  private_pem
    #   Location of the Private key in PEM format.
    def initialize( public_pem, private_pem = nil )
        @public_pem  = public_pem
        @private_pem = private_pem
    end

    # Encrypts data and returns a Base64 representation of the ciphertext
    # and AES CBC primitives encrypted using the public key.
    #
    # @param  [String]  data
    #
    # @return  [String]
    #   Base64 representation of the ciphertext and AES CBC primitives encrypted
    #   using the public key.
    def encrypt( data )
        rsa = OpenSSL::PKey::RSA.new( File.read( @public_pem ) )

        # encrypt with 256 bit AES with CBC
        aes = OpenSSL::Cipher::Cipher.new( 'aes-256-cbc' )
        aes.encrypt

        # use random key and IV
        aes.key = key = aes.random_key
        aes.iv  = iv  = aes.random_iv

        # this will hold all primitives and ciphertext
        primitives = {}

        primitives['ciphertext'] = aes.update( data )
        primitives['ciphertext'] << aes.final

        primitives['key'] = rsa.public_encrypt( key )
        primitives['iv']  = rsa.public_encrypt( iv )

        # serialize everything and base64 encode it
        Base64.encode64( primitives.to_yaml )
    end

    # Decrypts data.
    #
    # @param  [String]  data
    #
    # @return  [String]
    #   Plaintext.
    def decrypt( data )
        rsa = OpenSSL::PKey::RSA.new( File.read( @private_pem ) )

        # decrypt with 256 bit AES with CBC
        aes = OpenSSL::Cipher::Cipher.new( 'aes-256-cbc' )
        aes.decrypt

        # unencode and unserialize to get the primitives and ciphertext
        primitives = YAML::load( Base64.decode64( data ) )

        aes.key = rsa.private_decrypt( primitives['key'] )
        aes.iv  = rsa.private_decrypt( primitives['iv'] )

        plaintext = aes.update( primitives['ciphertext'] )
        plaintext << aes.final

        plaintext
    end

end

end
end
