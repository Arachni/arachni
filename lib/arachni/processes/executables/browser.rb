require 'childprocess'

def print_exception( e )
    puts_stderr "#{Process.pid}: [#{e.class}] #{e}"
    e.backtrace.each do |line|
        puts_stderr "#{Process.pid}: #{line}"
    end
rescue
end

def exit?
    $stdin.read_nonblock( 1 )
    false
rescue Errno::EWOULDBLOCK
    false
# Parent dead or willfully closed STDIN as a signal.
rescue EOFError, Errno::EPIPE => e
    print_exception( e )
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

    # Uncomment to show better error messages.
    # '--web-security=false',

    '--disk-cache=true'
)

handle_exit = proc do
    next if @called
    @called = true

    puts_stderr "#{Process.pid}: Exiting"

    begin
        process.stop
    rescue => e
        print_exception( e )
    end
end

at_exit( &handle_exit )

# Try our best to terminate cleanly if some external entity tries to kill us.
%w(EXIT TERM QUIT INT KILL).each do |signal|
    next if !Signal.list.include?( signal )
    trap( signal, &handle_exit ) rescue Errno::EINVAL
end

# Break out of the process group in order to ignore signals sent to the parent.
process.leader = true

# Forward output.
process.io.stdout = $stdout
process.io.stdout.sync = true

process.start
puts_stderr "#{Process.pid}: Started"

$stdout.puts "PID: #{process.pid}"

while !exit?
    begin
        break if !process.alive?

    # If for whatever reason we can't get a status on the browser consider it
    # dead.
    rescue => e
        print_exception( e )
        break
    end

    sleep 0.03
end

puts_stderr "#{Process.pid}: EOF"
