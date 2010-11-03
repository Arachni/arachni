#!/usr/bin/env ruby
=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'pp'
require 'ap'

$:.unshift( File.expand_path( File.dirname( __FILE__ ) ) )
require 'getoptslong.rb'
require Arachni::Options.instance.dir['lib'] + 'ui/xmlrpc/xmlrpc'

client = Arachni::UI::XMLRPC.new( Arachni::Options.instance )
client.run
