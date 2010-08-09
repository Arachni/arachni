=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# Overides Anemone's Page class methods:<br/>
# o in_domain?( uri ): adding support for subdomain crawling<br/> 
# o links(): adding support for frame and iframe src URLs<br/>
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class Anemone::Page

    alias :old_links :links
    
    #
    # Array of distinct A tag HREFs and (i)frame SRCs from the page<br/>
    # The original links() method takes care of A tags and the added code
    # takes care of (i)frame SRCs.
    #
    def links
        @links = old_links
        return @links if !doc
        
        doc.css('frame', 'iframe').each do |a|
            u = a.attributes['src'].content rescue nil
            next if u.nil? or u.empty?
            abs = to_absolute(URI(u)) rescue next
            @links << abs if in_domain?(abs)
        end
        
        @links.uniq!
        @links
    end

    #
    # Nokogiri document for the HTML body
    #
    def doc
      return @doc if @doc
#      @doc = Nokogiri::HTML( @body ) if @body && html? rescue nil
      @doc = Nokogiri::HTML( @body ) if @body rescue nil
    end

    
    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise.
    #
    # The added code enables optional subdomain crawling.
    #
    def in_domain?( uri )
        if( Arachni::Options.instance.follow_subdomains )
            return extract_domain( uri ) ==  extract_domain( @url )
        end

        uri.host == @url.host
    end

    #
    # Extracts the domain from a URI object
    #
    # @param [URI] url
    #
    # @return [String]
    #
    def extract_domain( url )

        if !url.host then return false end
            
        splits = url.host.split( /\./ )

        if splits.length == 1 then return true end

        splits[-2] + "." + splits[-1]
    end

end
