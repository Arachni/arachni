=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni::Mixins
end

lib = Arachni::Options.paths.mixins
require lib + 'observable'
require lib + 'terminal'
