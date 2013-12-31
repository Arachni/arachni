=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'singleton'
require 'ostruct'

lib = Arachni::Options.paths.lib
require lib + 'rpc/client/instance'
require lib + 'rpc/client/dispatcher'

lib = Arachni::Options.paths.lib + 'processes/'
require lib + 'manager'
require lib + 'dispatchers'
require lib + 'instances'
