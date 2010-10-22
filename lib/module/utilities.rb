=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module


#
# Utilities class
#
# Includes some useful methods for the system, the modules etc...
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
module Utilities

    #
    # Gets path from URL
    #
    # @param   [String]   url
    #
    # @return  [String]   path
    #
    def Utilities.get_path( url )

        filename = File.basename( URI( URI.escape( url ) ).path )
        regexp   = filename + '(.*)'
        path     = url.gsub( Regexp.new( regexp ), '' )

        if( path == 'http:' || path == 'https:' )
            path =  url
        end

        return path.chomp( '?' )
    end

    def Utilities.seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
    end

end

end
end
