=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end


module Arachni
module Modules
  
class SimpleRFI < Arachni::Module

  include Arachni::ModuleRegistrar
    
  def initialize( page_data, structure )
    super( page_data, structure )
    
    @page_data = page_data
  end

  def prepare( )
    puts '-------- In SimpleRFI.prepare()'
  end
  
  
  def run( )
    puts '-------- In SimpleRFI.run()'
    link = page_data['url']
    
    
    link['vars'].keys.each {
      |var|
      res = @http.get( link['href'], { var => 'http://www.google.com' } )
      
      if res.body.scan( /google/ixm )
        puts "------------ RFI Found in: var #{var}" + '::' + link['href']
      end
      
    }
  end

  def clean_up( )
    puts '-------- In SimpleRFI.clean_up()'
  end
  
  
  def self.info
    {
      'Name'           => 'SimpleRFI',
      'Description'    => %q{Simple Remote File Inclusion recon module},
      'Author'         => 'zapotek',
      'Version'        => '$Rev$',
      'References'     =>
      [
      ],
      'Targets'        => { 'PHP' => '5.1' }
    }
  end
  
end
end
end
