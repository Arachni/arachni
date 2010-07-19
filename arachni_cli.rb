#! /usr/bin/ruby
=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

require 'pp'
require 'ap'

require 'getoptslong'
require $runtime_args['dir']['lib'] + 'ui/cli/cli'

cli = Arachni::UI::CLI.new( $runtime_args )
cli.run
