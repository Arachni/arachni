=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
