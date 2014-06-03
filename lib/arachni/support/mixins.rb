=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Mixins
end

lib = Arachni::Options.paths.mixins
require lib + 'observable'
require lib + 'terminal'
