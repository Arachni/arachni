=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

lib = Arachni::Options.paths.lib
require lib + 'component/manager'
require lib + 'check/base'
require lib + 'check/manager'
