=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Watir
    class Element

        def events
            events = []

            browser.execute_script( 'return arguments[0].events();', self ).each do |event|
                events << [event.first.to_sym, event.last]
            end

            (::Arachni::Browser.events.flatten.map(&:to_s) & attributes).each do |event|
                events << [event.to_sym, attribute_value( event )]
            end

            events
        end

        def submit
            @element.submit
        end

        def opening_tag
            html.match( /<#{tag_name}.*?>/i )[0]
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
