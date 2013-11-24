=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'rubygems'
require 'bundler/setup'

module Arachni

    WEBSITE = 'http://arachni-scanner.com'
    WIKI    = "#{WEBSITE}/wiki"

    BANNER =<<EOBANNER
Arachni - Web Application Security Scanner Framework v#{VERSION}
   Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

           (With the support of the community and the Arachni Team.)

   Website:       #{WEBSITE}
   Documentation: #{WIKI}
EOBANNER

end
