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

module Arachni
module Component
module Options
#
# The following are pretty much rip offs of Metasploit's
# /lib/msf/core/option_container.rb
#
#

###
#
# The base class for all options.
#
###
class Base

    #
    # The name of the option.
    #
    attr_accessor :name

    #
    # Whether or not the option is required.
    #
    attr_reader :required

    #
    # The description of the option.
    #
    attr_reader :desc

    #
    # The default value of the option.
    #
    attr_reader :default

    #
    # The component that owns this option.
    #
    attr_accessor :owner

    #
    # The list of potential valid values
    #
    attr_accessor :enums


    #
    # Initializes a named option with the supplied attribute array.
    # The array is composed of three values.
    #
    # attrs[0] = required (boolean type)
    # attrs[1] = description (string)
    # attrs[2] = default value
    # attrs[3] = possible enum values
    #
    # @param    [String]    name    the name of the options
    # @param    [Array]     attrs   option attributes
    #
    def initialize( name, attrs = [] )
        @name     = name
        @required = attrs[0] || false
        @desc     = attrs[1]
        @default  = attrs[2]
        @enums    = [ *(attrs[3]) ].map { |x| x.to_s }
    end

    #
    # Returns true if this is a required option.
    #
    def required?
        required
    end

    #
    # Returns true if the supplied type is equivalent to this option's type.
    #
    def type?( in_type )
        type == in_type
    end

    #
    # If it's required and the value is nil or empty, then it's not valid.
    #
    def valid?( value )
        ( required? && ( value.nil? || value.to_s.empty? ) ) ? false : true
    end

    #
    # Returns true if the value supplied is nil and it's required to be
    # a valid value
    #
    def empty_required_value?( value )
        required? && value.nil?
    end

    #
    # Normalizes the supplied value to conform with the type that the option is
    # conveying.
    #
    def normalize( value )
        value
    end

    def type
        'abstract'
    end

    #
    # Converts the Options object to hash
    #
    # @return    [Hash]
    #
    def to_h
        hash = {}
        self.instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' )] = self.instance_variable_get( var )
        end
        hash.merge( 'type' => type )
    end

protected
    attr_writer :required, :desc, :default # :nodoc:

end

###
#
# Core option types.  The core supported option types are:
#
# OptString  - Multi-byte character string
# OptBool    - Boolean true or false indication
# OptPort    - TCP/UDP service port
# OptPath    - Path name on disk
# OptInt     - An integer value
# OptEnum    - Select from a set of valid values
#
###

###
#
# Mult-byte character string option.
#
###
class String < Base
    def type
        'string'
    end

    def normalize( value )
        if value =~ /^file:(.*)/
            path = $1
            begin
                value = File.read( path )
            rescue ::Errno::ENOENT, ::Errno::EISDIR
                value = nil
            end
        end
        value
    end

    def valid?( value = self.value )
        value = normalize( value )
        return false if empty_required_value?( value )
        super
    end
end

###
#
# Boolean option.
#
###
class Bool < Base
    TRUE_REGEX = /^(y|yes|t|1|true|on)$/i

    def type
        'bool'
    end

    def valid?( value )
        return false if empty_required_value?(value)

        if value && !value.to_s.empty? &&
            value.to_s.match( /^(y|yes|n|no|t|f|0|1|true|false|on)$/i )
            return false
        end

        true
    end

    def normalize( value )
        if value.nil? || value.to_s.match( TRUE_REGEX ).nil?
            false
        else
            true
        end
    end

    def is_true?( value )
        normalize( value )
    end

    def is_false?( value )
        !is_true?( value )
    end

end

###
#
# Enum option.
#
###
class Enum < Base

    def type
        'enum'
    end

    def valid?( value=self.value )
        return false if empty_required_value?( value )
        value && self.enums.include?( value.to_s )
    end

    def normalize( value = self.value )
        return nil if !self.valid?( value )
        value.to_s
    end

    def desc=( value )
        self.desc_string = value
        self.desc
    end

    def desc
        if self.enums
            str = self.enums.join( ', ' )
        end
        "#{self.desc_string || ''} (accepted: #{str})"
    end

protected
    attr_accessor :desc_string # :nodoc:
end

###
#
# Network port option.
#
###
class Port < Base
    def type
        'port'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.to_s.empty? &&
            ((!value.to_s.match( /^\d+$/ ) || value.to_i < 0 || value.to_i > 65535))
            return false
        end

        super
    end
end

###
#
# URL option.
#
###
class Url < Base
    def type
        'url'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.empty?
            require 'uri'
            require 'socket'
            begin
                ::IPSocket.getaddress( URI( value ).host )
            rescue
                return false
            end
        end

        super
    end
end


###
#
# Network address option.
#
###
class Address < Base
    def type
        'address'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.empty?
            require 'socket'
            begin
                ::IPSocket.getaddress( value )
            rescue
                return false
            end
        end

        super
    end
end


###
#
# File system path option.
#
###
class Path < Base
    def type
        'path'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.empty? && !File.exists?( value )
            return false
        end

        super
    end
end

###
#
# Integer option.
#
###
class Int < Base
    def type
        'integer'
    end

    def normalize( value )
        value.to_s.match( /^0x[a-fA-F\d]+$/ ) ? value.to_i(16) : value.to_i
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !normalize( value ).to_s.match( /^\d+$/ )
            return false
        end

        super
    end
end

###
#
# Floating point option.
#
###
class Float < Base
    def type
        'float'
    end

    def normalize( value )
        begin
            Float( value )
        rescue
            nil
        end
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !normalize( value ).to_s.match( /^\d+\.\d+$/ )
            return false
        end

        super
    end
end

end
end

    # Compat hack, makes options accessible as Arachni::Opt<type>
    Component::Options.constants.each do |sym|
        const_set( ('Opt' + sym.to_s).to_sym, Component::Options.const_get( sym ) )
    end

end
