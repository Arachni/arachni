=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

def require_lib( path )
    require Arachni::Options.paths.lib + path
end

def require_testee
    require Kernel.caller.first.split( ':' ).first.
                gsub( '/spec/arachni', '/lib/arachni' ).gsub( '_spec', '' )
end
