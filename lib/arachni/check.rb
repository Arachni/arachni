=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

lib = Arachni::Options.paths.lib
require lib + 'component/manager'
require lib + 'check/base'
require lib + 'check/manager'
