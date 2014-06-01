pid = Process.pid
SimpleCov.at_exit do
  SimpleCov.result.format! if Process.pid == pid
end

SimpleCov.start do
    add_filter do |source_file|
        path = source_file.filename
        path.start_with?( "#{Dir.pwd}/spec" ) ||
            # We can't monitor the server, they're forked.
            path.start_with?( "#{Dir.pwd}/lib/arachni/rpc/server" )
    end

    add_group 'Core' do |source_file|
        path = source_file.filename
        path.start_with?( "#{Dir.pwd}/lib/arachni" ) &&
            !path.start_with?( "#{Dir.pwd}/lib/arachni/rpc" )
    end

    add_group 'RPC' do |source_file|
        path = source_file.filename
        path.start_with?( "#{Dir.pwd}/lib/arachni/rpc" )
    end

    add_group 'Checks',          'components/checks'
    add_group 'Plugins',         'components/plugins'
    add_group 'Reports',         'components/reports'
    add_group 'Path extractors', 'components/path_extractors'
    add_group 'Fingerprinters',  'components/fingerprinters'
    add_group 'RPCD Handlers',   'components/rpcd_handlers'

    add_group 'UI', 'ui/'
end
