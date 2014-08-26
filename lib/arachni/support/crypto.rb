=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

lib = Arachni::Options.paths.support + 'crypto/'
require lib + 'rsa_aes_cbc'
