module Selenium
module WebDriver
class Element

    def html
        @bridge.executeScript( 'return arguments[0].outerHTML', self )
    end

    def opening_tag
        @bridge.executeScript(
            %Q[
                var s = '<' + arguments[0].tagName.toLowerCase();
                var attrs = arguments[0].attributes;
                for( var l = 0; l < attrs.length; ++l ) {
                    s += ' ' + attrs[l].name + '="' + attrs[l].value.replace( '"', '\"' ) + '"';
                }
                s += '>'
                return s;
            ],
            self
        )
    end

    def events
        (@bridge.executeScript( 'return arguments[0]._arachni_events;', self ) || []).
            map { |event, fn| [event.to_sym, fn] } |
            (::Arachni::Browser::Javascript.events.flatten.map(&:to_s) & attributes).
                map { |event| [event.to_sym, attribute( event )] }
    end

    def attributes
        @bridge.executeScript(
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
end
