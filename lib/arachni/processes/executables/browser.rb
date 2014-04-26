%w(QUIT INT).each do |signal|
    next if !Signal.list.has_key?( signal )
    trap( signal, 'IGNORE' )
end

File.open( $options[:comm_file], 'w' ) do |f|
    f.sync = true

    io = IO.popen([ 'phantomjs',
                    "--webdriver=#{$options[:port]}",
                    "--proxy=http://#{$options[:proxy]}/",
                    '--ignore-ssl-errors=true',
                    err: [:child, :out]]
    )
    Process.detach io.pid

    # Send the PID to the parent right away, he may need to kill PhantomJS if
    # initialization takes too long.
    f.puts io.pid.to_s

    # Wait for PhantomJS to initialize.
    buff = ''
    buff << io.gets.to_s while !buff.include?( 'running on port' )

    # All done, we're good to go.
    f.puts 'ping'
end
