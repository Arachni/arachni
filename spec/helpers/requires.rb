def require_from_root( path )
    require Arachni::Options.instance.dir['lib'] + path
end


def require_testee
    require Kernel::caller.first.split( ':' ).first.gsub( '/spec/arachni', '/lib/arachni' ).gsub( '_spec', '' )
end
