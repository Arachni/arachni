=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

lib = Arachni::Options.paths.support + 'cache/'
require lib + 'base'
require lib + 'least_recently_used'
require lib + 'random_replacement'
require lib + 'least_cost_replacement'
require lib + 'preference'
