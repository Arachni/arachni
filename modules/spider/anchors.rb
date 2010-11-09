
class Anchors < Anemone::Parser

    def parse( doc )
        doc.search( "//a[@href]" ).map { |a| a['href'] }
    end

end
