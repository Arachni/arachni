=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)
=end

module Arachni

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

class Base

    attr_reader :url
    attr_reader :action

    attr_reader :raw

    attr_reader :method

    def initialize( url, raw = {} )
        @raw   = raw.dup
        @url   = url.dup
    end


    def auditable

    end

    def id
        return @raw.to_s
    end

    def simple

    end

end

class Link < Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['href']
        @method = 'get'
    end

    def auditable
        return @raw['vars']
    end

    def simple
        return { @action => auditable }
    end

end


class Form < Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['attrs']['action']
        @method = @raw['attrs']['method']
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

end

class Cookie < Base


    def initialize( url, raw = {} )
        super( url, raw )

        @action = @url
        @method = 'cookie'
    end

    def auditable
        return { @raw['name'] => @raw['value'] }
    end

    def simple
        return auditable.dup
    end

end

class Header < Base


    def initialize( url, raw = {} )
        super( url, raw )

        @action = @url
        @method = 'header'
    end

    def auditable
        return @raw
    end

    def simple
        return auditable.dup
    end

end


end
end
end
