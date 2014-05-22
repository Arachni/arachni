=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::OptionGroups

# Holds options, and provides functionality, related to filling in inputs by name.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Input < Arachni::OptionGroup

    DEFAULT_VALUES = {
        /name/i    => 'arachni_name',
        /user/i    => 'arachni_user',
        /usr/i     => 'arachni_user',
        /pass/i    => '5543!%arachni_secret',
        /txt/i     => 'arachni_text',
        /num/i     => '132',
        /amount/i  => '100',
        /mail/i    => 'arachni@email.gr',
        /account/i => '12',
        /id/i      => '1',
    }

    DEFAULT = '1'

    # @return    [Hash<Regexp => String>]
    #   Patterns used to match input names and value to use to fill it in.
    attr_accessor :values

    # @return    [Hash<Regexp => String>]
    #   Default values for {#values}.
    #
    # @see DEFAULT_VALUES
    attr_accessor :default_values

    # @return   [Bool]
    #   `true` if {#default_values} should be used, `false` otherwise.
    attr_accessor :without_defaults

    # @return    [Bool]
    #   Force {#fill} all inputs, not just the empty ones.
    attr_accessor :force

    set_defaults(
        values:           {},
        default_values:   DEFAULT_VALUES,
        without_defaults: false,
        force:            false
    )

    # @note If {#force?} it will fill-in even non-empty inputs.
    #
    # Tries to fill a hash with values of appropriate type based on the key of
    # the parameter.
    #
    # @param  [Hash]  parameters
    #   Parameters hash.
    #
    # @return   [Hash]
    def fill( parameters )
        parameters = parameters.dup

        parameters.each do |k, v|
            next if !force? && !v.to_s.empty?

            value = value_for_name( k, false )

            # Don't overwrite the default values of the parameters unless we've
            # fot a value, even if #force? is in effect.
            if parameters[k].to_s.empty?
                parameters[k] = value || DEFAULT
            elsif value
                parameters[k] = value
            end
        end

        parameters
    end

    # @param    [String]    name
    #   Input name to match against {#effective_values}.
    #
    # @return   [String, nil]
    #   Value for the `name` or `nil` if none could be found.
    def value_for_name( name, use_default = true )
        effective_values.each { |k, v| return v if name =~ k }
        use_default ? DEFAULT : nil
    end

    # @return    [Hash<Regexp => String>]
    #   {#values}, merged with #{default_values} if {#without_defaults?}
    def effective_values
        without_defaults? ? @values : default_values.merge( @values )
    end

    # @param    [String]
    #   Location of a YAML file used to fill in {#values}.
    def update_values_from_file( location )
        @values.merge!( format_values( YAML.load_file( location ) ) )
    end

    # @return   [Bool]
    #   `true` if {#default_values} should be used, `false` otherwise.
    def without_defaults?
        !!@without_defaults
    end

    # @return    [Bool]
    #   Force {#fill} all inputs, not just the empty ones.
    def force?
        !!@force
    end

    # @private
    def values=( v )
        @values = format_values( v ) || defaults[:values]
    end

    # @private
    def default_values=( v )
        @default_values = format_values( v ) || defaults[:default_values]
    end

    # @private
    def format_values( values )
        return if !values

        values.inject({}) do |h, (regexp, value)|
            regexp = regexp.is_a?( Regexp ) ? regexp : Regexp.new( regexp.to_s )
            h.merge!( regexp => value )
            h
        end
    end

    def to_rpc_data
        d = super
        %w(values default_values).each do |k|
            d[k] = d[k].inject({}){ |h, (ck, v)| h[ck.source] = v; h }
        end
        d
    end

end
end
