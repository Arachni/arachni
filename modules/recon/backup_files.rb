=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Backup file discovery module.
#
# Appends common backup extesions to the filename of the page under audit<br/>
# and checks for its existence.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
#
class BackupFiles < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare
        # to keep track of the requests and not repeat them
        @@__audited ||= Set.new

        @@__extensions ||=[]
        return if !@@__extensions.empty?

        read_file( 'extensions.txt' ) {
            |file|
            @@__extensions << file
        }
    end

    def run( )

        path     = get_path( @page.url )

        return if @@__audited.include?( path )

        filename = File.basename( URI( normalize_url( @page.url ) ).path )

        print_status( "Scanning..." )

        if( !filename  )
            print_info( 'Backing out. ' +
              'Can\'t extract filename from url: ' + @page.url )
            return
        end

        @@__extensions.each {
            |ext|

            #
            # Test for the existance of the file + extension.
            #

            file = ext % filename # Example: index.php.bak
            check!( path, file )

            file = ext % filename.gsub( /\.(.*)/, '' ) # Example: index.bak
            check!( path, file )
        }

        @@__audited << path
    end

    def check!( path, file )

        url = path + file

        print_status( "Checking for #{url}" )

        log_remote_file_if_exists( url ) {
            |res|
            print_ok( "Found #{file} at " + res.effective_url )
        }
    end

    def self.info
        {
            :name           => 'BackupFiles',
            :description    => %q{Tries to find sensitive backup files.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.2',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A backup file exists on the server.},
                :description => %q{},
                :tags        => [ 'path', 'backup', 'file' ],
                :cew         => '530',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
