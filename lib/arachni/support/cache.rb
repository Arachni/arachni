=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

lib = Arachni::Options.paths.support + 'cache/'
require lib + 'base'
require lib + 'least_recently_used'
require lib + 'random_replacement'
require lib + 'least_cost_replacement'
require lib + 'preference'
