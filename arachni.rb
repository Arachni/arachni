#! /usr/bin/ruby
=begin
  $Id: arachni.rb 47 2010-06-29 20:35:49Z zapotek $

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

#
# Arachni driver
# Handles command line arguments and drives all the components of the system
#
# This is a temporary solution.
#
# @author: Zapotek <zapotek@segfault.gr>
# @version: 0.1-planning
#

require 'rubygems'
require 'getoptlong'
require 'lib/spider'
require 'lib/analyzer'
require 'lib/module/http'
require 'lib/module'
require 'lib/module_registrar'
require 'lib/module_registry'
require 'ap'
require 'pp'

VERSION  = '0.1-planning'
REVISION = '$Rev$'

require 'usage'

# Print out Arachni's banner
banner

require 'getoptslong'

if !$runtime_args[:audit_links] &&
   !$runtime_args[:audit_forms] &&
   !$runtime_args[:audit_cookies]
        
    puts "Error: No audit options were specified."
    puts "Run arachni with the '-h' parameter for help."
    puts
    exit 0
end

#
# make sure we have a user agent
#
if !$runtime_args[:user_agent]
    $runtime_args[:user_agent] = 'Arachni/' + VERSION
end

#
# Ensure that the user selected some modules
#
if !$runtime_args[:mods]
    puts "Error: No modules were specified."
    puts "Run arachni with the '-h' parameter for help or \n" +
    "with the '-l' parameter to see all available modules."
    puts
    exit 0
end

#
# Check the validity of user provided module names
#
modreg = Arachni::ModuleRegistry.new( $runtime_args['dir']['modules'] )
$runtime_args[:mods].each {
    |mod_name|

    if( !modreg.ls_available(  )[mod_name] )
        puts "Error: Module #{mod_name} wasn't found."
        puts "Run arachni with the '-l'" + 
            " parameter to see all available modules."
        exit 0
    end

    # load the module
    modreg.mod_load( mod_name )

}

#
# Try and parse URL.
# If it fails inform the user of that fact and
# give him some approriate examples.
#
begin
    $runtime_args[:url] = URI.parse( URI.encode( $runtime_args[:url] ) )
rescue
    puts "Error: Invalid URL argument."
    puts "URL must be of type 'scheme://username:password@subdomain." +
    "domain.tld:port/path?query_string#anchor'"
    puts "Be careful with the \"www\"."
    puts
    puts "Examples:"
    puts "    http://www.google.com"
    puts "    https://secure.wikimedia.org/wikipedia/en/wiki/Main_Page"
    puts "    http://zapotek:secret@www.myweb.com/index.php"
    puts
    exit 0
end

#
# If proxy type is socks include socksify
# and let it proxy all tcp connections for us.
#
# Then nil out the proxy opts or else they're going to be
# passed as an http proxy to Anemone::HTTP.refresh_connection()
#
if $runtime_args[:proxy_type] == 'socks'
    require 'socksify'

    TCPSocket.socks_server = $runtime_args[:proxy_addr]
    TCPSocket.socks_port = $runtime_args[:proxy_port]

    $runtime_args[:proxy_addr] = nil
    $runtime_args[:proxy_port] = nil
end

#ap $runtime_args

# Check for missing url
if $runtime_args[:url] == nil
    puts "Error: Missing url argument (try --help)"
    puts
    exit 0
end

spider   = Arachni::Spider.new( $runtime_args )
analyzer = Arachni::Analyzer.new( $runtime_args )
#spider.on_every_page( ) {
#  |page|
#  pp page
#}

#puts 'modreg:'
#puts '---------'
#pp modreg
#
#puts
#puts 'modreg.ls_available:'
#puts '---------'
#ap modreg.ls_available( )

#puts
#puts 'modreg.mod_load:'
#puts '---------'
#ap modreg.mod_load( 'test' )
#ap modreg.mod_load( 'test2' )

#puts
#puts 'modreg.ls_loaded:'
#puts '----------'
#ap modreg.ls_loaded( )
#puts

#puts
#puts 'modreg.mod_info:'
#puts '---------'
#modreg.ls_loaded.each_with_index {
#  |tmp, i|
#  ap modreg.mod_info( i )
#}
#puts

def run_mods( mods, page_data, structure )
    #  mods.each {
    #    |mod|
    #
    #    if $_interrupted == true
    #      puts
    #      puts 'Site audit was interrupted, exiting...'
    #      puts
    #      exit 0
    #    end
    #
    #    puts '+ ' + mod.to_s
    #    puts'---------------------------'
    ##      ap mod
    #    mod_new = mod.new( page_data, structure )
    ##      pp mod_new
    #
    #    mod_new.prepare
    #    mod_new.run
    #    mod_new.clean_up
    #    puts
    #  }
    mod_threads = []
    for mod in mods
        mod_threads << Thread.new( mod ) {
            |curr_mod|

            if $_interrupted == true
                puts
                puts 'Site audit was interrupted, exiting...'
                puts
                exit 0
            end

            puts '+ ' + mod.to_s
            puts'---------------------------'
            #      ap mod
            mod_new = mod.new( page_data, structure )
            #      pp mod_new

            mod_new.prepare
            mod_new.run
            mod_new.clean_up
        }
    end

    mod_threads.each { |thread|  thread.join }

end

puts
puts 'ModuleRegistry reports the following modules are loaded:'
puts '----------'
ap loaded_modules = modreg.ls_loaded( )
puts

structure = site_structure = Hash.new
mods_run_last_data = []

puts 'Analysing site structure...'
puts '---------------------------'
puts

$_interrupted = false
trap( "INT" ) { $_interrupted = true }
skip_to_audit = false

sitemap = spider.run {
    | url, html, headers |

    structure = site_structure[url] = analyzer.run( url, html, headers ).clone

    page_data = {
        'url' => { 'href' => url, 'vars' => analyzer.get_link_vars( url )},
        'html' => html,
        'headers' => headers
    }

    if !$runtime_args[:mods_run_last]
        run_mods( loaded_modules, page_data, structure )
    else

        if $_interrupted == true
            puts
            puts 'Site analysis was interrupted, do you want to audit' +
            ' the analyzed pages?'
            puts 'Audit?(\'y\' to audit, \'n\' to exit)(y/n)'

            if gets[0] == 'y'
                skip_to_audit = true
            else
                puts 'Exiting...'
                exit 0
            end

        end
        mods_run_last_data.push( { page_data => structure} )

    end

    if skip_to_audit == true
        puts 'Skipping to audit.'
        puts
        break
        $_interrupted = false
    end

}

if $runtime_args[:mods_run_last]

    mods_run_last_data.each {
        |data|
        run_mods( loaded_modules, data.keys[0], data.values[0] )
    }
end

#ap site_structure
#ap sitemap
#pp spider
