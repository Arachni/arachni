=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

def require_lib( path )
    require Arachni::Options.paths.lib + path
end

def require_testee
    require Kernel.caller.first.split( ':' ).first.
                gsub( '/spec/arachni', '/lib/arachni' ).gsub( '_spec', '' )
end
