=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Watir
class Element

    def opening_tag
        html.match( /<#{tag_name}.*?>/im )[0]
    end

    def events
        (browser.execute_script( 'return arguments[0].events;', self ) || []).
            map { |event, fn| [event.to_sym, fn] } |
            (::Arachni::Browser::Javascript.events.flatten.map(&:to_s) & attributes).
                map { |event| [event.to_sym, attribute_value( event )] }
    end

    def attributes
        browser.execute_script(
            %Q[
                var s = [];
                var attrs = arguments[0].attributes;
                for( var l = 0; l < attrs.length; ++l ) {
                    s.push( attrs[l].name );
                }
                return s;
            ],
            self
        )
    end

end
end
