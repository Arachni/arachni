=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)
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
        @url   = url.dup
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

end

class Link < Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['href']
        @method = 'get'

        @auditable = @raw['vars']
    end

    def http_request( url, opts )
        return @auditor.http.get( url, opts )
    end

    def simple
        return { @action => @auditable }
    end

    def type
        Arachni::Module::Auditor::Element::LINK
    end

    def audit_id( injection_str, opts = {} )
        vars = auditable.keys.sort.to_s
        url = URI( @auditor.page.url ).merge( URI( @action ).path ).to_s

        timeout = opts[:timeout] || ''
        return "#{@auditor.class.info[:name]}:" +
          "#{url}:" + "#{self.type}:" +
          "#{vars}=#{injection_str.to_s}:timeout=#{timeout}"
    end


end


class Form < Base

    include Arachni::Module::Utilities

    FORM_VALUES_ORIGINAL  = '__original_values__'
    FORM_VALUES_SAMPLE    = '__sample_values__'

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['attrs']['action']
        @method = @raw['attrs']['method']

        @auditable = simple['auditable'] || {}
    end

    def http_request( url, opts )


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
            return @auditor.http.post( url, opts )
        else
            return @auditor.http.get( url, opts )
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

        form = Hash.new

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

        @auditable = { @raw['name'] => @raw['value'] }
        @simple = @auditable.dup
        @auditable.reject! {
            |cookie|
            Options.instance.exclude_cookies.include?( cookie )
        }
    end

    def http_request( url, opts )
        return @auditor.http.cookie( url, opts )
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
    end

    def http_request( url, opts )
        return @auditor.http.header( url, opts )
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
