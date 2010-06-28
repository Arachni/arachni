#! /usr/bin/ruby
=begin
  $Id$

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
REVISION = '$Rev: 8 $'

require 'usage'

# Print out Arachni's banner
banner

require 'getoptslong'

#
# Try and parse URL.
# If it fails inform the user of that fact and
# give him some approriate examples.
#
$runtime_args[:url] = ARGV.shift
  
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

ap $runtime_args

# Check for missing url
if $runtime_args[:url] == nil
  puts "Error: Missing url argument (try --help)"
  puts
  exit 0
end

puts 'Analysing site structure...'

spider   = Arachni::Spider.new( $runtime_args )
analyzer = Arachni::Analyzer.new( $runtime_args )
#spider.on_every_page( ) {
#  |page|
#  pp page
#}

modreg = Arachni::ModuleRegistry.new( $runtime_args['dir']['modules'] )
  
puts 'modreg:'
puts '---------'
pp modreg

puts
puts 'modreg.ls_available:'
puts '---------'
ap modreg.ls_available( )

puts
puts 'modreg.mod_load:'
puts '---------'
ap modreg.mod_load( 'test' )
ap modreg.mod_load( 'test2' )

puts
puts 'modreg.ls_loaded:'
puts '----------'
ap modreg.ls_loaded( )
puts

puts
puts 'modreg.mod_info:'
puts '---------'
modreg.ls_loaded.each_with_index {
  |tmp, i|
  ap modreg.mod_info( i )
}
puts

structure = site_structure = Hash.new
sitemap = spider.run {
  | url, html, headers |
  
  
  structure = site_structure[url] = analyzer.run( url, html, headers ).clone
  
  page_data = {
    'url' => url,
    'html' => html,
    'headers' => headers 
  }  

}

ap site_structure
ap sitemap
#pp spider
