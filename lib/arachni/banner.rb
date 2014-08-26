=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'rubygems'
require 'bundler/setup'

module Arachni

    WEBSITE = 'http://arachni-scanner.com'
    WIKI    = "#{WEBSITE}/wiki"

    BANNER =<<EOBANNER
Arachni - Web Application Security Scanner Framework v#{VERSION}
   Author: Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>

           (With the support of the community and the Arachni Team.)

   Website:       #{WEBSITE}
   Documentation: #{WIKI}
EOBANNER

end
