require_relative '../../../../lib/arachni'

def framework
    @@framework ||= Arachni::Framework.new
end

def current_check
    @@current_check ||=
        framework.checks[ File.basename( caller.first.split( ':' ).first, '.rb' ) ]
end

def check_name
    File.basename( caller.first.split( ':' ).first, '.rb' )
end
