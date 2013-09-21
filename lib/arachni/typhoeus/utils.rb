=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Typhoeus::Utils
    def escape( s )
        s.encode( 'UTF-8', invalid: :replace, undef: :replace ).
            to_s.gsub( /([^ a-zA-Z0-9_.-]+)/u ) {
                '%' + $1.unpack( 'H2' * bytesize( $1 ) ).join( '%' ).upcase
            }.tr( ' ', '+' )
    end
    module_function :escape
end
