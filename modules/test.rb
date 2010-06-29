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
  
class Test < Arachni::Module

  include Arachni::ModuleRegistrar
    
  def initialize( page_data, structure )
    super( page_data, structure )
    
    @page_data = page_data
  end

  def prepare( )
    puts '-------- In Test.prepare()'
  end
  
  
  def run( )
    puts '-------- In Test.run()'
  end


  def clean_up( )
    puts '-------- In Test.clean_up()'
  end
  
  
  def self.info
    {
      'Name'           => 'Sample module Test1',
      'Description'    => %q{
        Sample module code. 
      },
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
