=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

HEADER = 'header'

class Header < Arachni::Element::Base

    def initialize( url, raw = {} )
        super( url, raw )

        self.action    = @url
        self.method    = 'get'
        self.auditable = @raw

        @orig = self.auditable.dup
        @orig.freeze
    end

    def simple
        @auditable.dup
    end

    def mutations( injection_str, opts = {} )
        flip = opts.delete( :param_flip )
        muts = super( injection_str, opts )

        if flip
            elem = self.dup

            # when under HPG mode element auditing is strictly regulated
            # and when we flip params we essentially create a new element
            # which won't be on the whitelist
            elem.override_instance_scope

            elem.altered = 'Parameter flip'
            elem.auditable = { injection_str => seed }
            muts << elem
        end

        muts
    end

    # @return   [String]    Header name.
    def name
        @auditable.first.first
    end

    # @return   [String]    Header value.
    def value
        @auditable.first.last
    end

    def type
        Arachni::Element::HEADER
    end

    def self.encode( header )
        ::URI.encode( header, "\r\n" )
    end
    def encode( header )
        self.class.encode( header )
    end

    def self.decode( header )
        ::URI.decode( header )
    end
    def decode( header )
        self.class.decode( header )
    end


    private
    def http_request( opts, &block )
        http.header( @action, opts, &block )
    end

end
end

Arachni::Header = Arachni::Element::Header
