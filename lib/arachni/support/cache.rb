=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

lib = Arachni::Options.dir['support'] + 'cache/'
require lib + 'base'
require lib + 'least_recently_used'
require lib + 'random_replacement'
require lib + 'least_cost_replacement'
require lib + 'preference'
