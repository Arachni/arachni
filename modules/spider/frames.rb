
class Frames < Anemone::Parser

    def parse( doc )
        doc.css( 'frame', 'iframe' ).map {
            |a|
            a.attributes['src'].content rescue next
        }
    end

end
