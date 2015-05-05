=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module Arachni::Element

# Represents an auditable form element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Form < Base
    require_relative 'form/dom'

    # Load and include all form-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include Arachni::Element::Capabilities::Analyzable
    include Arachni::Element::Capabilities::Refreshable

    # Form-specific overrides.
    include Capabilities::WithDOM
    include Capabilities::Auditable
    include Capabilities::Submittable
    include Capabilities::Mutable

    # {Form} error namespace.
    #
    # All {Form} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error

        # Raised when a specified form field could not be found/does not exist.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class FieldNotFound < Error
        end
    end

    ORIGINAL_VALUES = '__original_values__'
    SAMPLE_VALUES   = '__sample_values__'

    # @return     [String]
    #   The name of the input name that holds the nonce.
    attr_reader   :nonce_name

    # @return     [String, nil]
    #   Name of the form, if it has one.
    attr_accessor :name

    # @param    [Hash]    options
    # @option   options [String]    :name
    #   Form name.
    # @option   options [String]    :id
    #   Form ID.
    # @option   options [String]    :method (:get)
    #   Form method.
    # @option   options [String]    :url
    #   URL of the page which includes the form.
    # @option   options [String]    :action
    #   Form action -- defaults to `:url`.
    # @option   options [Hash]    :inputs
    #   Form inputs, can either be simple `name => value` pairs or more a
    #   more detailed representation such as:
    #
    #       {
    #           'my_token'  => {
    #               type:  :hidden,
    #               value: 'token-value'
    #           }
    #       }
    def initialize( options )
        super( options )

        @name = options[:name]
        @id   = options[:id]

        @input_details = {}

        cinputs = (options[:inputs] || {}).inject({}) do |h, (name, value_or_info)|
             if value_or_info.is_a? Hash
                 value_or_info             = value_or_info.my_symbolize_keys
                 h[name]                   = value_or_info[:value]
                 @input_details[name.to_s] = value_or_info
             else
                 h[name] = value_or_info
             end
                h
            end

        self.inputs = (method == :get ?
            (self.inputs || {}).merge(cinputs) : cinputs )

        @default_inputs = self.inputs.dup.freeze
    end

    def force_train?
        mutation_with_original_values? || mutation_with_sample_values?
    end

    # @param    [String]    input
    #   Input name.
    #
    # @return   [Hash]
    #   Information about the given input's attributes.
    def details_for( input )
        @input_details[input.to_s] || {}
    end

    # @return   [String]
    #   Name of ID HTML attributes for this form.
    def name_or_id
        name || @id
    end

    # @return   [Hash]
    #   A simple representation of self including attributes and inputs.
    def simple
        @initialization_options.merge( url: url, action: action, inputs: inputs )
    end

    def mirror_password_fields
        return if !requires_password?

        # if there are two password type fields in the form there's a good
        # chance that it's a 'please retype your password' thing so make sure
        # that we have a variation which has identical password values
        password_fields = inputs.keys.
            select { |input| field_type_for( input ) == :password }

        return if password_fields.size != 2

        self[password_fields[0]] = self[password_fields[1]]

        nil
    end

    # Checks whether or not the form contains 1 or more password fields.
    #
    # @return   [Bool]
    #   `true` if the form contains passwords fields, `false` otherwise.
    def requires_password?
        return @requires_password if !@requires_password.nil?
        inputs.each { |k, _| return @requires_password = true if field_type_for( k ) == :password }
        @requires_password = false
    end

    # @return   [Bool]
    #   `true` if the form contains a nonce, `false` otherwise.
    def has_nonce?
        !!nonce_name
    end

    # When `nonce_name` is set the value of the equivalent input will be
    # refreshed every time the form is to be submitted.
    #
    # Use only when strictly necessary because it comes with a hefty performance
    # penalty as the operation will need to be in blocking mode.
    #
    # Will raise an exception if `field_name` could not be found in the form's inputs.
    #
    # @example
    #   Form.new( 'http://stuff.com', { nonce_input: '' } ).nonce_name = 'blah'
    #   #=> #<Error::FieldNotFound: Could not find field named 'blah'.>
    #
    # @param    [String]    field_name
    #   Name of the field holding the nonce.
    #
    # @raise    [Error::FieldNotFound]
    #   If `field_name` is not a form input.
    def nonce_name=( field_name )
        if !has_inputs?( field_name )
            fail Error::FieldNotFound, "Could not find field named '#{field_name}'."
        end
        @nonce_name = field_name
    end

    # Retrieves a field type for the given field `name`.
    #
    # @example
    #    html_form = <<-HTML
    #    <form>
    #        <input type='text' name='text-input' />
    #        <input type='password' name='passwd' />
    #        <input type='hidden' name='cant-see-this' />
    #    </form>
    #    HTML
    #
    #    f = Form.from_document( 'http://stuff.com', html_form ).first
    #
    #    p f.field_type_for 'text-input'
    #    #=> :text
    #
    #    p f.field_type_for 'passwd'
    #    #=> :password
    #
    #    p f.field_type_for 'cant-see-this'
    #    #=> :hidden
    #
    # @param    [String]    name
    #   Field name.
    #
    # @return   [String]
    def field_type_for( name )
        details_for( name )[:type] || :text
    end

    def fake_field?( name )
        field_type_for( name ) == :fake
    end

    # @param   (see .encode)
    # @return  (see .encode)
    #
    # @see .encode
    def encode( str )
        self.class.encode( str )
    end

    # @param   (see .decode)
    # @return  (see .decode)
    #
    # @see .decode
    def decode( str )
        self.class.decode( str )
    end

    def dup
        super.tap do |f|
            f.nonce_name = nonce_name.dup if nonce_name

            f.mutation_with_original_values if mutation_with_original_values?
            f.mutation_with_sample_values   if mutation_with_sample_values?

            f.requires_password = requires_password?
        end
    end

    class <<self

        # Extracts forms by parsing the body of an HTTP response.
        #
        # @param   [Arachni::HTTP::Response]    response
        #
        # @return   [Array<Form>]
        def from_response( response, ignore_scope = false )
            from_document( response.url, response.body, ignore_scope )
        end

        # Extracts forms from an HTML document.
        #
        # @param    [String]    url
        #   URL of the document -- used for path normalization purposes.
        # @param    [String, Nokogiri::HTML::Document]    document
        #
        # @return   [Array<Form>]
        def from_document( url, document, ignore_scope = false )
            document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
            base_url = (document.search( '//base[@href]' )[0]['href'] rescue url)
            base_url = to_absolute( base_url, url )

            document.search( '//form' ).map do |node|
                next if !(forms = from_node( base_url, node, ignore_scope ))
                next if forms.empty?

                forms.each do |form|
                    form.url = url.freeze
                    form
                end
            end.flatten.compact
        end

        def from_node( url, node, ignore_scope = false )
            options          = attributes_to_hash( node.attributes )
            options[:url]    = url.freeze
            options[:action] = to_absolute( options[:action], url ).freeze
            options[:inputs] = {}
            options[:source] = node.to_html.freeze

            if (parsed_url = Arachni::URI( options[:action] ))
                return if !ignore_scope && parsed_url.scope.out?
            end

            # Forms can have many submit inputs with identical names but different
            # values, to act as a sort of multiple choice.
            # However, each Arachni Form can have only unique input names, so
            # we keep track of this here and create a new form for each choice.
            multiple_choice_submits = {}

            %w(textarea input select button).each do |attr|
                options[attr] ||= []
                node.search( ".//#{attr}" ).each do |elem|
                    elem_attrs = attributes_to_hash( elem.attributes )
                    elem_attrs[:type] = elem_attrs[:type].to_sym if elem_attrs[:type]

                    name = elem_attrs[:name] || elem_attrs[:id]
                    next if !name

                    # Handle the easy stuff first...
                    if elem.name != 'select'
                        options[:inputs][name]           = elem_attrs

                        if elem_attrs[:type] == :submit
                            multiple_choice_submits[name] ||= Set.new
                            multiple_choice_submits[name] <<
                                elem_attrs[:value]
                        end

                        options[:inputs][name][:type]  ||= :text
                        options[:inputs][name][:value] ||= ''
                        next
                    end

                    # If the select has options figure out which to use.
                    if elem.children.css('option').any?
                        elem.children.css('option').each do |child|
                            h = attributes_to_hash( child.attributes )
                            h[:type] = :select

                            # Prefer the selected or first option.
                            if h[:selected]
                                h[:value] ||= child.text
                                options[:inputs][name] = h
                            else
                                h[:value] ||= child.text
                                options[:inputs][name] ||= h
                            end
                        end

                        # The select has no options, use an empty string.
                    else
                        options[:inputs][name] = {
                            type:  :select,
                            value: ''
                        }
                    end
                end
            end

            return [new( options )] if multiple_choice_submits.empty?

            # If there are multiple submit with the same name but different values,
            # create forms for each value.
            multiple_choice_submits.map do |name, values|
                values.map.with_index do |value, i|

                    o = options
                    if values.size > 1
                        o = options.deep_clone
                        o[:inputs][name][:value] = value

                        # We need to add this here because if the forms have the
                        # same input names only the first one will be audited.
                        o[:inputs]["_#{name}_#{i}"] = {
                            type: :fake,
                            value: value
                        }
                    end

                    new( o )
                end
            end.flatten.compact
        end

        def attributes_to_hash( attributes )
            attributes.inject( {} ){ |h, (k, v)| h[k.to_sym] = v.to_s; h }
        end

        # Encodes a {String}'s reserved characters in order to prepare it
        # to be included in a request body.
        #
        # @param    [String]    str
        #
        # @return   [String]
        def encode( str )
            ::URI.encode_www_form_component str.to_s
        end

        # Decodes a {String} encoded for an HTTP request's body.
        #
        # @param    [String]    str
        #
        # @return   [String]
        def decode( str )
            ::URI.decode_www_form_component str.to_s
        end

    end

    protected

    def requires_password=( bool )
        @requires_password = bool
    end

    private

    def audit_single( payload, opts = {}, &block )
        opts = opts.dup

        if (each_m = opts.delete(:each_mutation))
            opts[:each_mutation] = proc do |mutation|
                next if mutation.mutation_with_original_values? ||
                    mutation.mutation_with_sample_values?

                each_m.call( mutation )
            end
        end

        super( payload, opts, &block )
    end

    def skip?( elem )
        if elem.mutation_with_original_values? || elem.mutation_with_sample_values?
            id = elem.audit_id
            return true if audited?( id )
            audited( id )
        end
        false
    end

    def http_request( options, &block )
        if force_train? && options[:train] != false
            print_debug 'Submitting form with default or sample values,' <<
                            ' overriding trainer option.'
            options[:train] = true
            print_debug_trainer( options )
        end

        options = options.dup

        if has_nonce?
            print_info "Refreshing nonce for '#{nonce_name}'."

            if !refresh
                print_bad 'Could not refresh nonce because the original form ' <<
                              'could not be found.'
            else
                print_info "Got new nonce '#{inputs[nonce_name]}'."
                options[:mode]       = :sync
                options[:parameters] = inputs
            end
        end

        self.method == :post ?
            http.post( self.action, options, &block ) :
            http.get( self.action, options, &block )
    end

end
end

Arachni::Form = Arachni::Element::Form
