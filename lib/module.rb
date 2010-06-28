=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni
  
#
# Arachni::Module class<br/>
# Module base class, to be extended by Arachni::Modules
# Defined basic structure and provides utilities to modules.
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class Module
  
  #
  # Hash page data (url, html, headers) 
  #
  # @return [Hash<String, String>]
  #
  attr_reader :page_data

  #
  # Structure of the website
  #
  # @return [Hash<String, Hash<Array, Hash>>]
  #
  attr_reader :structure
  
  #
  # Initializes the module attributes and HTTP client
  #
  # @param  [Hash<String, String>]  page_data
  #
  # @param [Hash<String, Hash<Array, Hash>>]  structure
  #
  def initialize( page_data, structure )
    @http = Arachni::HTTP.new( page_data['url'] )
    
    @page_data = page_data
    @structure = structure
  end
  
  #
  # Returns forms from @structure
  #
  def get_forms
    @structure['forms']
  end

  #
  # Returns links from @structure
  #
  def get_links
    @structure['links']
  end
  
  #
  # Returns cookies from @structure
  #
  def get_cookies
    @structure['cookies']
  end
  
end
end