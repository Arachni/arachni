=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Modules

#
# CVS/SVN users recon module.
#
# Scans every page for CVS/SVN users.
#
# @author   Tasos Laskos <tasos.laskos@gmail.com>
# @version  0.2
#
class CvsSvnUsers < Arachni::Module::Base

    def run
        regexps = [
            /\$Author: (.*) \$/,
            /\$Locker: (.*) \$/,
            /\$Header: .* (.*) (Exp )?\$/,
            /\$Id: .* (.*) (Exp )?\$/
        ]

        matches = regexps.map {
            |regexp|
            @page.html.scan( regexp )
        }.flatten.reject{ |match| !match || match =~ /Exp/ }.map{ |match| match.strip }.uniq

        matches.each {
            |match|
            log(
                :regexp  => regexps.to_s,
                :match   => match,
                :element => Issue::Element::BODY
            )
        }

    end

    def self.info
        {
            :name           => 'CVS/SVN users',
            :description    => %q{Scans every page for CVS/SVN users.},
            :author         => 'Tasos Laskos <tasos.laskos@gmail.com>',
            :version        => '0.2',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{CVS/SVN user disclosure.},
                :description => %q{A CVS or SVN user is disclosed in the body of the HTML page.},
                :cwe         => '200',
                :severity    => Issue::Severity::LOW,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Remove all CVS and SVN users from the body of the HTML page.},
                :remedy_code => '',
            }
        }
    end

end
end
end
