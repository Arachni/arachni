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

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/auditable'

class Parser

module Element

#
# Base element class.
#
# Should be extended/implemented by all HTML/HTTP modules.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @abstract
#
class Base < Arachni::Element::Auditable

    #
    # The URL of the page that owns the element.
    #
    # @return  [String]
    #
    attr_accessor :url

    #
    # The url to which the element points and should be audited against.
    #
    # Ex. 'href' for links, 'action' for forms, etc.
    #
    # @return  [String]
    #
    attr_accessor :action

    attr_accessor :auditable

    attr_accessor :orig

    #
    # Relatively 'raw' hash holding the element's attributes, values, etc.
    #
    # @return  [Hash]
    #
    attr_accessor :raw

    #
    # Method of the element.
    #
    # Should represent a method in {Arachni::Module::HTTP}.
    #
    # Ex. get, post, cookie, header
    #
    # @see Arachni::Module::HTTP
    #
    # @return [String]
    #
    attr_accessor :method

    #
    # Initialize the element.
    #
    # @param    [String]  url     {#url}
    # @param    [Hash]    raw     {#raw}
    #
    def initialize( url, raw = {} )
        @raw   = raw.dup
        @url   = url.to_s
    end

    #
    # Must provide a string uniquely identifying self.
    #
    # @return  [String]
    #
    def id
        return @raw.to_s
    end

    #
    # Must provide a simple hash representation of self
    #
    def simple

    end

    #
    # Must provide the element type, one of {Arachni::Module::Auditor::Element}.
    #
    def type

    end

    def dup
        self.class.new( @url.dup, @raw.dup )
    end

end

class Link < Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['href'] || @raw[:href] || @raw['action'] || @raw[:action] || url
        @method = 'get'

        @auditable = @raw['vars'] || @raw[:vars] || @raw['inputs'] || @raw[:inputs]
        @orig      = @auditable.deep_clone
        @orig.freeze
    end

    def http_request( opts )
        return @auditor.http.get( @action, opts )
    end

    def simple
        return { @action => @auditable }
    end

    def type
        Arachni::Module::Auditor::Element::LINK
    end

    def audit_id( injection_str = '', opts = {} )
        vars = auditable.keys.sort.to_s
        url = @action.gsub( /\?.*/, '' )

        str = ''
        str += !opts[:no_auditor] ? "#{@auditor.class.info[:name]}:" : ''

        str += "#{url}:" + "#{self.type}:#{vars}"
        str += "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str += ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        return str
    end


end


class Form < Base

    include Arachni::Module::Utilities

    FORM_VALUES_ORIGINAL  = '__original_values__'
    FORM_VALUES_SAMPLE    = '__sample_values__'

    def initialize( url, raw = {} )
        super( url, raw )

        begin
            @action = @raw['action'] || @raw[:action] || @raw['attrs']['action']
        rescue
            @action = url
        end

        begin
            @method = @raw['method'] || @raw[:method] || @raw['attrs']['method']
        rescue
            @method = 'post'
        end

        @auditable = @raw[:inputs] || @raw['inputs'] || simple['auditable'] || {}
        @orig      = @auditable.deep_clone
        @orig.freeze
    end

    def http_request( opts )
        params   = opts[:params]
        altered  = opts[:altered]

        curr_opts = opts.dup
        if( altered == FORM_VALUES_ORIGINAL )
            orig_id = audit_id( FORM_VALUES_ORIGINAL )

            return if !opts[:redundant] && audited?( orig_id )
            audited( orig_id )

            print_debug( 'Submitting form with original values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end

        if( altered == FORM_VALUES_SAMPLE )
            sample_id = audit_id( FORM_VALUES_SAMPLE )

            return if !opts[:redundant] && audited?( sample_id )
            audited( sample_id )

            print_debug( 'Submitting form with sample values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end


        if( @method.downcase != 'get' )
            return @auditor.http.post( @action, opts )
        else
            return @auditor.http.get( @action, opts )
        end
    end

    def id
        id = simple['attrs'].to_s

        auditable.map {
            |name, value|
            next if name.substring?( seed )
            id +=  name
        }

        return id
    end

    def simple
        form = {}

        return form if !@raw || !@raw['auditable'] || @raw['auditable'].empty?

        form['attrs'] = @raw['attrs']
        form['auditable'] = {}
        @raw['auditable'].each {
            |item|
            if( !item['name'] ) then next end
            form['auditable'][item['name']] = item['value']
        }

        return form.dup
    end

    def type
        Arachni::Module::Auditor::Element::FORM
    end

end

class Cookie < Base


    def initialize( url, raw = {} )
        super( url, raw )

        @action = @url
        @method = 'cookie'

        if @raw['name'] && @raw['value']
            @auditable = { @raw['name'] => @raw['value'] }
        else
            @auditable = raw.dup
            @raw = {
                'name'  => @auditable.keys.first,
                'value' => @auditable.values.first
            }
        end

        @simple = @auditable.dup
        @auditable.reject! {
            |cookie|
            Options.instance.exclude_cookies.include?( cookie )
        }

        @orig      = @auditable.deep_clone
        @orig.freeze
    end

    def http_request( opts )
        return @auditor.http.cookie( @action, opts )
    end

    def simple
        return @simple
    end

    def type
        Arachni::Module::Auditor::Element::COOKIE
    end

end

class Header < Base


    def initialize( url, raw = {} )
        super( url, raw )

        @action = @url
        @method = 'header'

        @auditable = @raw
        @orig      = @auditable.deep_clone
        @orig.freeze
    end

    def http_request( opts )
        return @auditor.http.header( @action, opts )
    end

    def simple
        return @auditable.dup
    end

    def type
        Arachni::Module::Auditor::Element::HEADER
    end

end


end
end
end
