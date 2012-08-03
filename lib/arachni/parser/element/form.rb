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

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/element/base'

class Arachni::Parser::Element::Form < Arachni::Parser::Element::Base

    ORIGINAL_VALUES = '__original_values__'
    SAMPLE_VALUES   = '__sample_values__'

    attr_accessor :nonce_name

    #
    # Creates a new Form element from a URL and auditable data.
    #
    # @param    [String]    url     owner URL -- URL of the page which contained the
    # @param    [Hash]    raw
    #   If empty, the element will be initialized without auditable inputs.
    #
    #   If a full +Hash+ is passed, it will look for an actionable URL
    #   +String+ in the following keys:
    #   * 'href'
    #   * :href
    #   * 'action'
    #   * :action
    #
    #   For an method +String+ in:
    #   * 'method'
    #   * :method
    #
    #   For an auditable inputs +Hash+ in:
    #   * 'inputs'
    #   * :inputs
    #   * 'auditable'
    #
    #   these should contain inputs in name=>value pairs.
    #
    def initialize( url, raw = {} )
        super( url, raw )

        was_opts_hash = false
        begin
            self.action = @raw['action'] || @raw[:action] || @raw['attrs']['action']
            was_opts_hash = true
        rescue
            self.action = self.url
        end

        begin
            self.method = @raw['method'] || @raw[:method] || @raw['attrs']['method']
            was_opts_hash = true
        rescue
            self.method = 'post'
        end

        if !was_opts_hash && (@raw.keys & [:inputs, 'inputs', 'auditable']).empty?
            self.auditable = @raw
        else
            self.auditable = @raw[:inputs] || @raw['inputs'] || simple['auditable']
        end

        self.auditable ||= {}

        @orig = self.auditable.dup
        @orig.freeze
    end

    #
    # @return   [String, nil]   name of the form if it has one
    #
    def name
        @raw['attrs']['name'] if @raw['attrs'].is_a?( Hash )
    end

    #
    # @return   [String]    unique form ID
    #
    def id
        query_vars = parse_url_vars( self.action )
        "#{self.action.split( '?' ).first.to_s.split( ';' ).first}::" <<
            "#{self.method}::#{query_vars.merge( self.auditable ).keys.compact.sort.to_s}"
    end

    #
    # @return   [Hash]    a simple representation of self including attributes and auditables
    #
    def simple
        form = {}

        form['auditable'] = {}
        if @raw['auditable'] && !@raw['auditable'].empty?
            @raw['auditable'].each do |item|
                next if !item['name']
                form['auditable'][item['name']] = item['value']
            end
        end

        if @raw['attrs']
            form['attrs'] = @raw['attrs']
        else
            form['attrs'] = {
                'method' => @method,
                'action' => @action
            }
        end

        if form['auditable'].empty? && @auditable && !@auditable.empty?
            form['auditable'] = @auditable
        end

        form.dup
    end

    # @return   [Bool]  +true+ if the element has not been mutated, +false+ otherwise.
    def original?
        self.altered == ORIGINAL_VALUES
    end

    # @return   [Bool]  +true+ if the element has been populated with sample values,
    #                     +false+ otherwise.
    def sample?
        self.altered == SAMPLE_VALUES
    end

    def audit_id( injection_str = '', opts = {} )
        str = if original?
                  opts[:no_auditor] = true
                  ORIGINAL_VALUES
              elsif sample?
                  opts[:no_auditor] = true
                  SAMPLE_VALUES
              else
                  injection_str
              end

        super( str, opts )
    end

    #
    # Overrides {Arachni::Parser::Element::Mutable#mutations} adding support
    # for mutations with:
    # * sample values (filled by {Arachni::Module::KeyFiller.fill})
    # * original values
    # * password fields with identical values (in order to pass server-side validation)
    #
    # @return   [Array<Form>]
    #
    # @see Arachni::Parser::Element::Mutable#mutations
    # @see Arachni::Module::KeyFiller.fill
    #
    def mutations( injection_str, opts = {} )
        opts = MUTATION_OPTIONS.merge( opts )
        var_combo = super( injection_str, opts )

        if !opts[:skip_orig]
            # this is the original hash, in case the default values
            # are valid and present us with new attack vectors
            elem = self.dup
            elem.altered = ORIGINAL_VALUES
            var_combo << elem

            elem = self.dup
            elem.auditable = Arachni::Module::KeyFiller.fill( auditable.dup )
            elem.altered = SAMPLE_VALUES
            var_combo << elem
        end

        return var_combo.uniq if !@raw['auditable']

        # if there are two password type fields in the form there's a good
        # chance that it's a 'please retype your password' thing so make sure
        # that we have a variation which has identical password values
        filled_auditables = Arachni::Module::KeyFiller.fill( auditable.dup )
        delem = self.dup

        found_passwords = false
        @raw['auditable'].each do |input|
            if input['type'] == 'password'
                delem.altered = input['name']

                opts[:format].each do |format|
                    filled_auditables[input['name']] =
                        format_str( injection_str, filled_auditables[input['name']], format )
                end

                found_passwords = true
            end
        end

        if found_passwords
            delem.auditable = filled_auditables
            var_combo << delem
        end

        var_combo.uniq
    end

    # @return   [String]    'form'
    def type
        Arachni::Module::Auditor::Element::FORM
    end

    #
    # Returns an array of forms by parsing the body of an HTTP response.
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Form>]
    #
    def self.from_response( response )
        from_document( response.effective_url, response.body )
    end

    #
    # Returns an array of forms from an HTML document.
    #
    # @param    [String]    url     request URL
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Form>]
    #
    def self.from_document( url, document )
        document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
        base_url = url
        begin
            base_url = document.search( '//base[@href]' )[0]['href']
        rescue
            base_url = url
        end
        document.search( '//form' ).map do |form|
            form = form_from_element( base_url, form )
            form.url = url
            form
        end.compact
    end

    def has_nonce?
        !!!nonce_name
    end

    def field_type_for( name )
        field = @raw['auditable'].select { |f| f['name'] == name }.first
        return if !field
        field['type'].to_s.downcase
    end

    def self.encode( str )
        ::URI.encode( ::URI.encode( str, '+' ).gsub( ' ', '+' ), ';&\\=' )
    end

    def encode( str )
        self.class.encode( str )
    end

    def dup
        f = super
        f.nonce_name = nonce_name.dup if nonce_name
        f
    end

    private

    def skip?( elem )
        if elem.original? || elem.sample?
            id = elem.audit_id
            return true if audited?( id )
            audited( id )
        end
        false
    end

    def self.form_from_element( url, form )
        c_form = {}
        c_form['attrs'] = attributes_to_hash( form.attributes )

        if !c_form['attrs'] || !c_form['attrs']['action']
            action = url.to_s
        else
            action = url_sanitize( c_form['attrs']['action'] )
        end

        begin
             action = to_absolute( action.dup, url ).to_s
        rescue
        end

        c_form['attrs']['action'] = action

        if !c_form['attrs']['method']
            c_form['attrs']['method'] = 'get'
        else
            c_form['attrs']['method'] = c_form['attrs']['method'].downcase
        end

        %w(textarea input select).each do |attr|
            c_form[attr] ||= []
            form.search( ".//#{attr}" ).each do |elem|

                elem_attrs = attributes_to_hash( elem.attributes )
                c_form[elem.name] ||= []
                if elem.name != 'select'
                    c_form[elem.name] << elem_attrs
                else
                    auditables = elem.children.map do |child|
                        h = attributes_to_hash( child.attributes )
                        h['value'] ||= child.text
                        h['options'] ||= {}
                        h
                    end

                    c_form[elem.name] << {
                        'attrs'   => elem_attrs,
                        'options' => auditables
                    }
                end
            end
        end

        # merge the form elements to make auditing easier
        c_form['auditable'] = c_form['input'] | c_form['textarea']
        c_form['auditable'] =
            merge_select_with_input( c_form['auditable'], c_form['select'] )

        new( url, c_form )
    end

    def self.attributes_to_hash( attributes )
        attributes.inject( {} ){ |h, (k, v)| h[k] = v.to_s; h }
    end

    #
    # Merges an array of form inputs with an array of form selects
    #
    # @param    [Array]  inputs
    # @param    [Array]  selects
    #
    # @return   [Array]  merged array
    #
    def self.merge_select_with_input( inputs, selects )
        selected = nil
        inputs | selects.map do |select|
            select['options'].each do |option|
                if option.include?( 'selected' )
                    selected = option['value']
                    break
                end
            end

            select['attrs']['value'] = selected || begin
                select['options'].first['value']
            rescue
            end
            select['attrs']
        end
    end

    def http_request( opts, &block )
        if (original? || sample?) && opts[:train] != false
            state = original? ? 'original' : 'sample'
            print_debug "Submitting form with #{state} values; overriding trainer option."
            opts[:train] = true
            print_debug_trainer( opts )
        end

        if nonce_name
            print_info "Refreshing nonce for '#{nonce_name}'."

            res = http.get( @url, async: false ).response
            f = self.class.from_response( res ).select { |f| f.auditable.keys == auditable.keys }.first
            if !f
                print_bad 'Could not refresh nonce because the form could not be found.'
            else
                nonce = f.auditable[nonce_name]

                print_info "Got new nonce '#{nonce}'."

                opts[:params][nonce_name] = nonce
                opts[:async] = false
            end

            self.method.downcase.to_s != 'get' ?
                http.post( self.action, opts, &block ) : http.get( self.action, opts, &block )
        else
            self.method.downcase.to_s != 'get' ?
                http.post( self.action, opts, &block ) : http.get( self.action, opts, &block )
        end
    end

end
