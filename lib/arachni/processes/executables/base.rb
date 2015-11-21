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
            alive = false
            @wmi ||= WIN32OLE.connect( 'winmgmts://' )
            processes = @wmi.ExecQuery( "select ProcessId from win32_process where ProcessID='#{ppid}'")
            processes.each do |proc|
                alive = true
            end
            processes.ole_free

            return alive
        rescue WIN32OLERuntimeError
        end
    end

    !!(Process.kill( 0, ppid ) rescue false)
end

load ARGV.pop
