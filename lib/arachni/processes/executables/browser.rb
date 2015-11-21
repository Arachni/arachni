require 'childprocess'

executable = $options[:executable]
port       = $options[:port]
proxy_url  = $options[:proxy_url]

process = ChildProcess.build(
    executable,
    "--webdriver=#{port}",
    "--proxy=#{proxy_url}",

    # As lax as possible to allow for easy SSL interception.
    # The actual request to the origin server will obey
    # the system-side SSL options.
    '--ignore-ssl-errors=true',
    '--ssl-protocol=any',

    '--disk-cache=true'
)

handle_exit = proc do
    process.stop
    # $stderr.puts "#{Process.pid}: Exited"
end

trap( 'INT', &handle_exit )
at_exit( &handle_exit )

process.detach = true

# Forward output.
process.io.stderr = $stderr
process.io.stdout = $stdout
process.io.stderr.sync = process.io.stdout.sync = true

process.start

# $stderr.puts "#{Process.pid}: Started"

# Bail out if either the parent of the browser dies.
while parent_alive?
    # $stderr.puts "#{Process.pid}: Working"

    begin
        break if !process.alive?
    rescue Errno::ECHILD
        exit
    end

    sleep 0.5
end
