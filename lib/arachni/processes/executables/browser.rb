require 'childprocess'

def exit?
    $stdin.read_nonblock( 1 )
    false
rescue Errno::EWOULDBLOCK
    false
# Parent dead or willfully closed STDIN as a signal.
rescue EOFError, Errno::EPIPE => e
    # $stderr.puts "#{Process.pid}: [#{e.class}] #{e}"
    true
end

executable = $options[:executable]
port       = $options[:port]
proxy_url  = $options[:proxy_url]

process = ChildProcess.build(
    executable,
    "--webdriver=#{port}",
    "--proxy=#{proxy_url}",

    # As lax as possible to allow for easy SSL interception.
    # The actual request to the origin server will obey the system-side SSL options.
    '--ignore-ssl-errors=true',
    '--ssl-protocol=any',

    '--disk-cache=true'
)

handle_exit = proc do
    # $stderr.puts "#{Process.pid}: Exiting"
    process.stop rescue nil
end

at_exit( &handle_exit )

# Try our best to terminate cleanly if some external entity tries to kill us.
%w(EXIT TERM QUIT INT KILL).each do |signal|
    next if !Signal.list.include?( signal )
    trap( signal, &handle_exit ) rescue Errno::EINVAL
end

process.detach = true

# Forward output.
process.io.stdout = $stdout
process.io.stdout.sync = true

process.start
# $stderr.puts "#{Process.pid}: Started"

$stdout.puts "PID: #{process.pid}"

while !exit?
    # $stderr.puts "#{Process.pid}: Working"

    begin
        break if !process.alive?

    # If for whatever reason we can't get a status on the browser consider it
    # dead.
    rescue => e
        # $stderr.puts "#{Process.pid}: [#{e.class}] #{e}"
        break
    end

    sleep 0.03
end

# $stderr.puts "#{Process.pid}: EOF"
