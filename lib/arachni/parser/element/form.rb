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

    FORM_VALUES_ORIGINAL  = '__original_values__'
    FORM_VALUES_SAMPLE    = '__sample_values__'

    def initialize( url, raw = {} )
        super( url, raw )

        begin
            self.action = @raw['action'] || @raw[:action] || @raw['attrs']['action']
        rescue
            self.action = self.url
        end

        begin
            self.method = @raw['method'] || @raw[:method] || @raw['attrs']['method']
        rescue
            self.method = 'post'
        end

        self.auditable = @raw[:inputs] || @raw['inputs'] || simple['auditable'] || {}

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
        id = simple['attrs'].to_s
        auditable.each do |name, _|
            next if name.substring?( seed )
            id +=  name
        end
        id
    end

    #
    # @return   [Hash]    a simple representation of self including attributes and auditables
    #
    def simple
        form = {}

        if @raw['attrs']
            form['attrs'] = @raw['attrs']
            form['auditable'] = {}
            if @raw['auditable'] && !@raw['auditable'].empty?
                @raw['auditable'].each do |item|
                    next if !item['name']
                    form['auditable'][item['name']] = item['value']
                end
            end
        else
            form = {
                'attrs' => {
                    'method' => @method,
                    'action' => @action
                },
                'auditable' => @auditable
            }
        end

        form['auditable'] ||= {}
        form.dup
    end

    #
    # @return   [String]    'form'
    #
    def type
        Arachni::Module::Auditor::Element::FORM
    end

    #
    # Returns an array of forms based on HTTP response.
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Form>]
    #
    def self.from_response( response )
        from_document( response.effective_url, response.body )
    end

    #
    # Returns an array of forms from a document.
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

    private

    def self.form_from_element( url, form )
        utilities = Arachni::Module::Utilities

        c_form = {}
        c_form['attrs'] = attributes_to_hash( form.attributes )

        if !c_form['attrs'] || !c_form['attrs']['action']
            action = url.to_s
        else
            action = utilities.url_sanitize( c_form['attrs']['action'] )
        end

        begin
             action = utilities.to_absolute( action.dup, url ).to_s
        rescue
        end

        c_form['attrs']['action'] = action

        if !c_form['attrs']['method']
            c_form['attrs']['method'] = 'post'
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

            select['attrs']['value'] = selected || select['options'].first['value']
            select['attrs']
        end
    end

    def http_request( opts, &block )
        params   = opts[:params]
        altered  = opts[:altered]

        curr_opts = opts.dup
        if altered == FORM_VALUES_ORIGINAL
            orig_id = audit_id( FORM_VALUES_ORIGINAL )

            return if !opts[:redundant] && audited?( orig_id )
            audited!( orig_id )

            print_debug( 'Submitting form with original values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end

        if altered == FORM_VALUES_SAMPLE
            sample_id = audit_id( FORM_VALUES_SAMPLE )

            return if !opts[:redundant] && audited?( sample_id )
            audited!( sample_id )

            print_debug( 'Submitting form with sample values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end

        @method.downcase.to_s != 'get' ? http.post( @action, opts, &block ) : http.get( @action, opts, &block )
    end

end
