=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

buffers = Arachni::Options.paths.support + 'buffer/'
require buffers + 'base'
require buffers + 'autoflush'
