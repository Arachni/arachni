=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Plugins::Proxy

#
# Helper class including method for rendering templates for the proxy.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
class TemplateScope
    include Arachni::Utilities
    include Arachni::UI::Output

    PANEL_BASEDIR  = "#{Arachni::Plugins::Proxy::BASEDIR}panel/"
    PANEL_TEMPLATE = "#{PANEL_BASEDIR}panel.html.erb"
    PANEL_URL      = "#{Arachni::Plugins::Proxy::BASE_URL}panel/"

    def initialize( params = {} )
        update( params )
    end

    def self.new( *args )
        @self ||= super( *args )
    end

    def self.get
        new
    end

    def root_url
        PANEL_URL
    end

    def js_url
        "#{root_url}js/"
    end

    def css_url
        "#{root_url}css/"
    end

    def img_url
        "#{root_url}img/"
    end

    def inspect_url
        "#{root_url}inspect"
    end

    def shutdown_url
        url_for :shutdown
    end

    def vectors_url
        "#{root_url}vectors.yml"
    end

    def url_for( *args )
        Arachni::Plugins::Proxy.url_for( *args )
    end

    def update( params )
        params.each { |name, value| set( name, value ) }
        self
    end

    def set( name, value )
        self.class.send( :attr_accessor, name )
        instance_variable_set( "@#{name.to_s}", value )
        self
    end

    def content_for?( ivar )
        !!instance_variable_get( "@#{ivar.to_s}" )
    end

    def content_for( name, value = :nil )
        if value == :nil
            instance_variable_get( "@#{name.to_s}" )
        else
            set( name, html_encode( value.to_s ) )
            nil
        end
    end

    def erb( tpl, params = {} )
        params = params.dup
        params[:params] ||= {}

        with_layout = true
        with_layout = !!params.delete( :layout ) if params.include?( :layout )
        format       = params.delete( :format ) || 'html'

        update( params )

        tpl = "#{tpl}.#{format}.erb" if tpl.is_a?( Symbol )

        path = File.exist?( tpl ) ? tpl : PANEL_BASEDIR + tpl

        evaled = ERB.new( IO.read( path ) ).result( get_binding )
        with_layout ? layout { evaled } : evaled
    end

    def render( tpl, opts )
        erb tpl, opts.merge( layout: false )
    rescue => e
        print_error "Error when rendering: #{tpl}"
        print_exception e
        nil
    end

    def layout
        ERB.new( IO.read( PANEL_BASEDIR + 'layout.html.erb' ) ).result( binding )
    end

    def panel
        erb :panel
    end

    def get_binding
        binding
    end

    def clear
        instance_variables.each { |v| instance_variable_set( v, nil ) }
    end
end
end

