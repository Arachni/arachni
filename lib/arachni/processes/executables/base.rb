require 'base64'

$options = Marshal.load( Base64.strict_decode64( ARGV.pop ) )

if !$options[:without_arachni]
    require 'arachni'

    include Arachni
    Options.update $options.delete(:options)
else
    if Gem.win_platform?
        require 'Win32API'
        require 'win32ole'
    end
end

def ppid
    $options[:ppid]
end

def parent_alive?
    # Windows is not big on POSIX so try it its own way if possible.
    if Gem.win_platform?
        begin
            wmi = WIN32OLE.connect( 'winmgmts://' )
            wmi.InstancesOf( 'Win32_Process' ).each do |proc|
                return true if ppid == proc.ProcessId
            end

            return false
        rescue WIN32OLERuntimeError
        end
    end

    !!(Process.kill( 0, ppid ) rescue false)
end

load ARGV.pop
