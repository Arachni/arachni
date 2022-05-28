=begin
=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Adobe AEM specific resources. 
# Adobe AEM is a java and OSGi based CMS framework commonly used among big enterprises.
# AEM can be fingerprinted by very specific paths starting with /etc/designs, etc.clientlibs, _jcr_content or containing the granite element in it's path.
# Old AEM versions also expose the name Day-Servlet-Engine in the server header
#
# @author Thomas Hartmann <thomysec@gmx.org>
# @version 0.1
class AdobeAem < Platform::Fingerprinter

    def run
        if uri.path =~ /.etc\/designs\d*\/*/ || 
            uri.path =~ /.etc\.clientlib\d*\/*/ ||
            uri.path =~ /.jcr_content\d*\/*/ ||
            uri.path =~ /.granite\d*\/*/ ||
            server_or_powered_by_include?( 'Day-Servlet-Engine' )

             platforms << :java << :adobeaem
        end
    end

end

end
end