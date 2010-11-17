=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Modules

#
# CVS/SVN users recon module.
#
# Scans every page for CVS/SVN users.
#
# @author: morpheuslaw <msidagni@nopsec.com>
# @version: 0.1
#
class CvsSvnUsers < Arachni::Module::Base

    def initialize( page )
        @page = page
    end

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
            log_match(
                :regexp  => regexps.to_s,
                :match   => match,
                :element => Vulnerability::Element::BODY
            )
        }

    end

    def self.info
        {
            :name           => 'CVS/SVN users',
            :description    => %q{Scans every page for CVS/SVN users.},
            :author         => 'morpheuslaw <msidagni@nopsec.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{CVS/SVN user disclosure.},
                :description => %q{A CVS or SVN user is disclosed in the body of the HTML page.},
                :cwe         => '200',
                :severity    => Vulnerability::Severity::LOW,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Remove all CVS and SVN users from the body of the HTML page.},
                :remedy_code => '',
            }
        }
    end

end
end
end
