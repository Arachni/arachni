=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

#
# Overides Anemone's Page class method in_domain?( uri )
# adding support for subdomain crawling
#
class Anemone::Page
  
  #
  # Returns +true+ if *uri* is in the same domain as the page, returns
  # +false+ otherwise
  #
  def in_domain?( uri )
    
    if $opts[:follow_subdomains]
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
    splits = url.host.split( /\./ )
    splits[-2] + "." + splits[-1]
  end
  
end