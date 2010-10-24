=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)
=end

module Arachni

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/auditable'

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @abstract
#
class Parser

module Element

class Base < Arachni::Element::Auditable

    attr_reader :url
    attr_reader :action

    attr_reader :raw

    attr_reader :method

    def initialize( url, raw = {} )
        @raw   = raw.dup
        @url   = url.dup
    end

    def http( url, opts )
    end


    def id
        return @raw.to_s
    end

    def simple

    end

    def type

    end

end

class Link < Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['href']
        @method = 'get'
    end

    def http_request( url, opts )
        return @auditor.http.get( url, opts )
    end

    def auditable
        return @raw['vars']
    end

    def simple
        return { @action => auditable }
    end

    def type
        Arachni::Module::Auditor::Element::LINK
    end

    def audit_id( injection_str )
        vars = auditable.keys.sort.to_s
        url = URI( @auditor.page.url ).merge( URI( @action ).path ).to_s

        return "#{@auditor.class.info[:name]}:" +
          "#{url}:" + "#{self.type}:" +
          "#{vars}=#{injection_str.to_s}"
    end


end


class Form < Base

    FORM_VALUES_ORIGINAL  = '__original_values__'
    FORM_VALUES_SAMPLE    = '__sample_values__'

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['attrs']['action']
        @method = @raw['attrs']['method']
    end

    def http_request( url, opts )


        params   = opts[:params]
        altered  = opts[:altered]

        curr_opts = opts.dup
        if( altered == FORM_VALUES_ORIGINAL )
            orig_id = audit_id( params.values | ["{#{FORM_VALUES_ORIGINAL}}"] )

            return if !opts[:redundant] && audited?( orig_id )
            audited( orig_id )

            print_debug( 'Submitting form with original values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end

        if( altered == FORM_VALUES_SAMPLE )
            sample_id = audit_id( params.values | ["{#{FORM_VALUES_SAMPLE}}"] )

            return if !opts[:redundant] && audited?( sample_id )
            audited( sample_id )

            print_debug( 'Submitting form with sample values;' +
                ' overriding trainer option.' )
            opts[:train] = true
            print_debug_trainer( opts )
        end


        if( method.downcase != 'get' )
            return @auditor.http.post( url, opts )
        else
            return @auditor.http.get( url, opts )
        end
    end

    def auditable
        return simple['auditable'] || {}
    end

    def id

        id = simple['attrs'].to_s

        auditable.map {
            |item|
            citem = item.clone
            citem.delete( 'value' )
            id +=  citem.to_s
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
    end

    def http_request( url, opts )
        return @auditor.http.cookie( url, opts )
    end

    def auditable
        return { @raw['name'] => @raw['value'] }
    end

    def simple
        return auditable.dup
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
    end

    def http_request( url, opts )
        return @auditor.http.header( url, opts )
    end

    def auditable
        return @raw
    end

    def simple
        return auditable.dup
    end

    def type
        Arachni::Module::Auditor::Element::HEADER
    end

end


end
end
end
