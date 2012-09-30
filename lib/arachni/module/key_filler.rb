=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni::Module

#
# KeyFiller class
#
# Included by {Module::Auditor}
#
# Tries to fill in input parameters with values of proper type
# based on their name.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class KeyFiller

    # Hash of regexps for the parameter keys
    # and the values to to fill in
    #
    # @return  [Hash]
    #
    @@regexps = {
        'name'    => 'arachni_name',
        'user'    => 'arachni_user',
        'usr'     => 'arachni_user',
        'pass'    => '5543!%arachni_secret',
        'txt'     => 'arachni_text',
        'num'     => '132',
        'amount'  => '100',
        'mail'    => 'arachni@email.gr',
        'account' => '12',
        'id'      => '1'
    }

    def self.regexps
        @@regexps
    end

    #
    # Tries to fill a hash with values of appropriate type<br/>
    # based on the key of the parameter.
    #
    # @param  [Hash]  hash   hash of name=>value pairs
    #
    # @return   [Hash]
    #
    def self.fill( hash )
        hash = hash.dup
        hash.keys.each do |key|
            next if hash[key] && !hash[key].empty?

            if val = self.match?( key )
                hash[key] = val
            end

            # moronic default value...
            # will figure  out something better in the future...
            hash[key] = '1' if( !hash[key] || hash[key].empty? )
        end

        hash
    end

    private

    def self.match?( str )
      @@regexps.keys.each { |key| return @@regexps[key] if str =~ Regexp.new( key, 'i' ) }
      false
    end

end

end
