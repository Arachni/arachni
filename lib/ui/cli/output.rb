=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

module UI

module Output

    @@verbose = false
    @@debug   = false
    @@only_positives  = false
    
    def print_color( sign, color, string )
        print "\033[1;#{color.to_s}m #{sign}\033[1;00m #{string}\n";
    end
    
    def print_error( str = '' )
        print_color( '[-]', 31, str )
    end
    
    def print_status( str = '' )
        if @@only_positives then return end
        print_color( '[*]', 34, str )
    end
    
    def print_info( str = '' )
        if @@only_positives then return end
        print_color( '[~]', 30, str )
    end
    
    def print_ok( str = '' )
        print_color( '[+]', 32, str )
    end
    
    def print_debug( str = '' )
        if !@@debug then return end
        print_color( '[!]', 36, str )
    end

    def print_debug_pp( obj = nil )
        if !@@debug then return end
        pp obj
    end
        
    def print_verbose( str = '' )
        if !@@verbose then return end
        print_color( '[v]', 37, str )
    end
    
    def print_line( str = '' )
        if @@only_positives then return end
        puts str
    end
    
    def verbose!
        @@verbose = true
    end
    
    def verbose?
        @@verbose
    end
    
    def debug!
        @@debug = true
    end

    def debug?
        @@debug
    end
        
    def only_positives!
        @@only_positives = true
    end
    
    def only_positives?
        @@only_positives
    end
end

end
end
