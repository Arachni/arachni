require_relative '../../../../lib/arachni'

def framework
    @@framework ||= Arachni::Framework.new
end

def current_module
    @@current_module ||=
        framework.modules[ File.basename( caller.first.split( ':' ).first, '.rb' ) ]
end

def module_name
    File.basename( caller.first.split( ':' ).first, '.rb' )
end
