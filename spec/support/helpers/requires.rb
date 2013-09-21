=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

def require_lib( path )
    require Arachni::Options.dir['lib'] + path
end

def require_testee
    require Kernel.caller.first.split( ':' ).first.
                gsub( '/spec/arachni', '/lib/arachni' ).gsub( '_spec', '' )
end
