=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

lib = Arachni::Options.paths.support + '/database/'
require lib + 'base'
require lib + 'queue'
require lib + 'hash'
