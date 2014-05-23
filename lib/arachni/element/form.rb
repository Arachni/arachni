=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'base'
require_relative 'capabilities/with_node'

module Arachni::Element

# Represents an auditable form element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Form < Base
    require_relative 'form/dom'

    include Capabilities::WithNode
    include Capabilities::WithDOM
    include Capabilities::Analyzable
    include Capabilities::Refreshable

    # {Form} error namespace.
    #
    # All {Form} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error

        # Raised when a specified form field could not be found/does not exist.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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

        self.inputs = (options[:inputs] || {}).
            inject({}) do |h, (name, value_or_info)|

             if value_or_info.is_a? Hash
                 value_or_info             = value_or_info.symbolize_keys
                 h[name]                   = value_or_info[:value]
                 @input_details[name.to_s] = value_or_info
             else
                 h[name] = value_or_info
             end
                h
            end

        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !node || inputs.empty?
        super
    end

    def force_train?
        mutation_with_original_values || mutation_with_sample_values
    end

    # @param    (see Capabilities::Submittable#action=)
    # @@return  (see Capabilities::Submittable#action=)
    def action=( url )
        v = super( url )
        @query_vars   = parse_url_vars( v )
        @audit_id_url = v.split( '?' ).first.to_s
        v
    end

    # @param    [String]    input
    #   Input name.
    # @return   [Hash]
    #   Information about the given input's attributes.
    def details_for( input )
        @input_details[input.to_s] || {}
    end

    # @return   [String]
    def to_html
        @html
    end

    # @return   [String]
    #   Name of ID HTML attributes for this form.
    def name_or_id
        name || @id
    end

    # @return   [String]
    #   Unique form ID.
    def id
        id_from :inputs
    end

    def id_from( type = :inputs )
        "#{@audit_id_url}:#{self.method}:" <<
            "#{@query_vars.merge( self.send( type ) ).keys.compact.sort.to_s}"
    end

    # @return   [Hash]
    #   A simple representation of self including attributes and inputs.
    def simple
        @initialization_options.merge( url: url, action: action, inputs: inputs )
    end

    # @return   [Bool]
    #   `true` if the element has not been mutated, `false` otherwise.
    def mutation_with_original_values?
        !!@mutation_with_original_values
    end

    def mutation_with_original_values
        @mutation_with_original_values = true
    end

    # @return   [Bool]
    #   `true` if the element has been populated with sample
    #   ({Arachni::OptionGroups::Input.fill}) values, `false` otherwise.
    #
    # @see Arachni::OptionGroups::Input
    def mutation_with_sample_values?
        !!@mutation_with_sample_values
    end

    def mutation_with_sample_values
        @mutation_with_sample_values = true
    end

    # @param    (see Capabilities::Auditable#audit_id)
    # @@return  (see Capabilities::Auditable#audit_id)
    def audit_id( injection_str = '', opts = {} )
        str = if mutation_with_original_values?
                  opts[:no_auditor] = true
                  ORIGINAL_VALUES
              elsif mutation_with_sample_values?
                  opts[:no_auditor] = true
                  SAMPLE_VALUES
              else
                  injection_str
              end

        super( str, opts )
    end

    # Overrides {Arachni::Element::Mutable#each_mutation} adding support
    # for mutations with:
    #
    # * Sample values (filled by {Arachni::OptionGroups::Input.fill}).
    # * Original values.
    # * Password fields requiring identical values (in order to pass
    #   server-side validation)
    #
    # @param    [String]    seed    Seed to inject.
    # @param    [Hash]      opts    Mutation options.
    # @option   opts    [Bool]  :skip_original
    #   Whether or not to skip adding a mutation holding original values and
    #   sample values.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    # @see Arachni::OptionGroups::Input.fill
    def each_mutation( seed, opts = {} )
        opts = MUTATION_OPTIONS.merge( opts )

        generated = Arachni::Support::LookUp::HashSet.new

        super( seed, opts ) do |elem|
            elem.mirror_password_fields
            yield elem if !generated.include?( elem )
            generated << elem
        end

        return if opts[:skip_original]

        elem = self.dup
        elem.mutation_with_original_values
        elem.affected_input_name  = ORIGINAL_VALUES
        yield elem if !generated.include?( elem )
        generated << elem

        # Default values, in case they reveal new resources.
        if node
            inputs.keys.each do |input|
                next if field_type_for( input ) != :select

                node.xpath( "select[@name=\"#{input}\"]" ).css('option').each do |option|
                    elem = self.dup
                    elem.mutation_with_original_values
                    elem.affected_input_name  = input
                    elem.affected_input_value = option['value'] || option.text
                    yield elem if !generated.include?( elem )
                    generated << elem
                end
            end
        end

        # Sample values, in case they reveal new resources.
        elem = self.dup
        elem.inputs = Arachni::Options.input.fill( inputs.dup )
        elem.affected_input_name = SAMPLE_VALUES
        elem.mutation_with_sample_values
        yield elem if !generated.include?( elem )
        generated << elem
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

    # @return   [Bool]  `true` if the form contains a nonce, `false` otherwise.
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
    #   #=> #<RuntimeError: Could not find field named 'blah'.>
    #
    # @param    [String]    field_name  Name of the field holding the nonce.
    #
    # @raise    [Error::FieldNotFound]  If `field_name` is not a form input.
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
    # @param    [String]    name    Field name.
    #
    # @return   [String]
    def field_type_for( name )
        details_for( name )[:type]
    end

    # @see .parse_request_body
    def parse_request_body( body )
        self.class.parse_request_body( body )
    end

    # @see .encode
    def encode( str )
        self.class.encode( str )
    end

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
        def from_response( response )
            from_document( response.url, response.body )
        end

        # Extracts forms from an HTML document.
        #
        # @param    [String]    url
        #   URL of the document -- used for path normalization purposes.
        # @param    [String, Nokogiri::HTML::Document]    document
        #
        # @return   [Array<Form>]
        def from_document( url, document )
            document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
            base_url = url
            begin
                base_url = document.search( '//base[@href]' )[0]['href']
            rescue
                base_url = url
            end
            document.search( '//form' ).map do |cform|
                next if !(form = form_from_element( base_url, cform ))
                form.url = url.freeze
                form
            end.compact
        end

        # Parses an HTTP request body generated by submitting a form.
        #
        # @param    [String]    body
        #
        # @return   [Hash]      Parameters.
        def parse_request_body( body )
            body.to_s.split( '&' ).inject( {} ) do |h, pair|
                name, value = pair.split( '=', 2 )
                h[decode( name.to_s )] = decode( value )
                h
            end
        end

        def form_from_element( url, form )
            c_form          = attributes_to_hash( form.attributes )
            c_form[:url]    = url.freeze
            c_form[:action] = to_absolute( c_form[:action], url ).freeze
            c_form[:inputs] = {}
            c_form[:html]   = form.to_html.freeze

            %w(textarea input select button).each do |attr|
                c_form[attr] ||= []
                form.search( ".//#{attr}" ).each do |elem|
                    elem_attrs = attributes_to_hash( elem.attributes )
                    elem_attrs[:type] = elem_attrs[:type].to_sym if elem_attrs[:type]

                    name = elem_attrs[:name] || elem_attrs[:id]
                    next if !name

                    # Handle the easy stuff first...
                    if elem.name != 'select'
                        c_form[:inputs][name]           = elem_attrs
                        c_form[:inputs][name][:type]  ||= :text
                        c_form[:inputs][name][:value] ||= ''
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
                                c_form[:inputs][name] = h
                            else
                                h[:value] ||= child.text
                                c_form[:inputs][name] ||= h
                            end
                        end

                        # The select has no options, use an empty string.
                    else
                        c_form[:inputs][name] = {
                            type:  :select,
                            value: ''
                        }
                    end
                end
            end

            new c_form
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
            ::URI.encode(
                ::URI.encode( str, '+%' ).recode.gsub( ' ', '+' ),
                ";&\\=\0"
            )
        end

        # Decodes a {String} encoded for an HTTP request's body.
        #
        # @param    [String]    str
        #
        # @return   [String]
        def decode( str )
            URI.decode( str.to_s.recode.gsub( '+', ' ' ) )
        end

    end

    protected

    def requires_password=( bool )
        @requires_password = bool
    end

    private

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
                options[:mode] = :sync
            end
        end

        self.method == :post ?
            http.post( self.action, options, &block ) :
            http.get( self.action, options, &block )
    end

end
end

Arachni::Form = Arachni::Element::Form
