=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
