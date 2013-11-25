=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

lib = Arachni::Options.dir['lib']
require lib + 'component/manager'
require lib + 'check/base'
require lib + 'check/manager'
