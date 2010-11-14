=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

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
class OptBase

    #
    # The name of the option.
    #
    attr_reader   :name

    #
    # Whether or not the option is required.
    #
    attr_reader   :required

    #
    # The description of the option.
    #
    attr_reader   :desc

    #
    # The default value of the option.
    #
    attr_reader   :default

    #
    # Storing the name of the option.
    #
    attr_writer   :name

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
        return required
    end

    #
    # Returns true if the supplied type is equivalent to this option's type.
    #
    def type?( in_type )
        return (type == in_type)
    end

    #
    # If it's required and the value is nil or empty, then it's not valid.
    #
    def valid?( value )
        return ( required? && ( value == nil || value.to_s.empty? ) ) ? false : true
    end

    #
    # Returns true if the value supplied is nil and it's required to be
    # a valid value
    #
    def empty_required_value?( value )
        return ( required? && value.nil? )
    end

    #
    # Normalizes the supplied value to conform with the type that the option is
    # conveying.
    #
    def normalize( value )
        value
    end

protected

    attr_writer   :required, :desc, :default # :nodoc:
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
class OptString < OptBase
    def type
        return 'string'
    end

    def normalize(value)
        if (value =~ /^file:(.*)/)
            path = $1
            begin
                value = File.read(path)
            rescue ::Errno::ENOENT, ::Errno::EISDIR
                value = nil
            end
        end
        value
    end

    def valid?(value=self.value)
        value = normalize(value)
        return false if empty_required_value?(value)
        return super
    end
end

###
#
# Boolean option.
#
###
class OptBool < OptBase

    TrueRegex = /^(y|yes|t|1|true)$/i

    def type
        return 'bool'
    end

    def valid?(value)
        return false if empty_required_value?(value)

        if ((value != nil and
            (value.to_s.empty? == false) and
            (value.to_s.match(/^(y|yes|n|no|t|f|0|1|true|false)$/i) == nil)))
            return false
        end

        true
    end

    def normalize(value)
        if(value.nil? or value.to_s.match(TrueRegex).nil?)
            false
        else
            true
        end
    end

    def is_true?(value)
        return normalize(value)
    end

    def is_false?(value)
        return !is_true?(value)
    end

end

###
#
# Enum option.
#
###
class OptEnum < OptBase

    def type
        return 'enum'
    end

    def valid?(value=self.value)
        return false if empty_required_value?(value)

        (value and self.enums.include?(value.to_s))
    end

    def normalize(value=self.value)
        return nil if not self.valid?(value)
        return value.to_s
    end

    def desc=(value)
        self.desc_string = value

        self.desc
    end

    def desc
        if self.enums
            str = self.enums.join(', ')
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
class OptPort < OptBase
    def type
        return 'port'
    end

    def valid?(value)
        return false if empty_required_value?(value)

        if ((value != nil and value.to_s.empty? == false) and
            ((value.to_s.match(/^\d+$/) == nil or value.to_i < 0 or value.to_i > 65535)))
            return false
        end

        return super
    end
end

###
#
# File system path option.
#
###
class OptPath < OptBase
    def type
        return 'path'
    end

    def valid?(value)
        return false if empty_required_value?(value)

        if ((value != nil and value.empty? == false) and
            (File.exists?(value) == false))
            return false
        end

        return super
    end
end

###
#
# Integer option.
#
###
class OptInt < OptBase
    def type
        return 'integer'
    end

    def normalize(value)
        if (value.to_s.match(/^0x[a-fA-F\d]+$/))
            value.to_i(16)
        else
            value.to_i
        end
    end

    def valid?(value)
        return false if empty_required_value?(value)

        if value and not normalize(value).to_s.match(/^\d+$/)
            return false
        end

        return super
    end
end

end

