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

Gem::Specification.new do |s|
      require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/version'

      s.required_ruby_version = '>= 1.9.2'

      s.name              = "arachni"
      s.version           = Arachni::VERSION
      s.date              = Time.now.strftime( '%Y-%m-%d' )
      s.summary           = "Arachni is a feature-full, modular, high-performance Ruby framework aimed towards helping penetration testers and administrators evaluate the security of web applications."
      s.homepage          = "https://github.com/Arachni/arachni"
      s.email             = "tasos.laskos@gmail.com"
      s.authors           = [ "Tasos Laskos" ]
      s.files            += Dir.glob("conf/**/**")
      s.files            += Dir.glob("data/**/**")
      s.files            += Dir.glob("external/**/**")
      s.files            += Dir.glob("extras/**/**")
      s.files            += Dir.glob("gfx/**/**")
      s.files            += Dir.glob("lib/**/**")
      s.files            += Dir.glob("logs/**/**")
      s.files            += Dir.glob("modules/**/**")
      s.files            += Dir.glob("path_extractors/**/**")
      s.files            += Dir.glob("plugins/**/**")
      s.files            += Dir.glob("profiles/**/**")
      s.files            += Dir.glob("reports/**/**")
      s.files            += Dir.glob("rpcd_handlers/**/**")
      s.files            += Dir.glob("spec/**/**")
      s.files            += %w(Gemfile Rakefile arachni.gemspec)

      s.executables       = [ "arachni", "arachni_rpcd_monitor",
                              "arachni_rpcd", "arachni_rpc", "arachni_web",
                              "arachni_web_autostart", "arachni_console",
                              "arachni_script" ]

      s.extra_rdoc_files  = %w( README.md ACKNOWLEDGMENTS.md LICENSE.md AUTHORS.md CHANGELOG.md CONTRIBUTORS.md EXPLOITATION.md HACKING.md NOTICE )
      s.rdoc_options      = ["--charset=UTF-8"]

      s.add_dependency 'bundler',         ">= 1.0.0"
      s.add_dependency "typhoeus",        "~> 0.3.3"
      #s.add_dependency "addressable",     "~> 2.2.6"
      s.add_dependency "pony"
      s.add_dependency "awesome_print"
      s.add_dependency "json"
      s.add_dependency "rb-readline"
      s.add_dependency "nokogiri",        ">= 1.5.0"
      s.add_dependency "sys-proctable",   ">= 0.9.1"
      s.add_dependency "terminal-table",  ">= 1.4.2"
      s.add_dependency "sinatra",         "~> 1.3.2"
      s.add_dependency "sinatra-contrib", "~> 1.3.1"
      s.add_dependency "sinatra-flash",   ">= 0.3.0"
      s.add_dependency "async_sinatra",   ">= 0.5.0"
      s.add_dependency "thin",            ">= 1.2.11"
      s.add_dependency "datamapper",      "~> 1.2.0"
      s.add_dependency "data_objects",    "~> 0.10.8"
      s.add_dependency "dm-sqlite-adapter", "~> 1.2.0"
      s.add_dependency "net-ssh",         ">= 2.2.1"
      s.add_dependency "net-scp",         ">= 1.0.4"
      s.add_dependency "eventmachine",    ">= 1.0.0.beta.4"
      s.add_dependency "em-synchrony",    ">= 1.0.0"
      s.add_dependency "arachni-rpc-em",  "= 0.1.2"

      s.add_development_dependency 'rake',  "~> 0.9.2.2"
      s.add_development_dependency 'rspec', "~> 2.8"

      s.post_install_message = <<MSG

Thank you for installing Arachni, here are some resources which should
help you make the best of it:

Homepage           - http://arachni-scanner.com
Blog               - http://arachni-scanner.com/blog
Documentation      - http://arachni-scanner.com/wiki
Support            - http://support.arachni-scanner.com
GitHub page        - http://github.com/Arachni/arachni
Code Documentation - http://rubydoc.info/github/Arachni/arachni
Author             - Tasos "Zapotek" Laskos (http://twitter.com/Zap0tek)
Twitter            - http://twitter.com/ArachniScanner
Copyright          - 2010-2012 Tasos Laskos
License            - Apache License v2

Please do not hesitate to ask for assistance (via the support portal)
or report a bug (via GitHub Issues) if you come across any problem.

MSG

      s.description = <<DESCRIPTION
Arachni is a feature-full, modular, high-performance Ruby framework aimed towards
helping penetration testers and administrators evaluate the security of web applications.

Arachni is smart, it trains itself by learning from the HTTP responses it receives during the audit process
and is able to perform meta-analysis using a number of factors in order to correctly assess the trustworthiness
of results and intelligently identify false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications, can detect changes caused while travelling
through the paths of a web application's cyclomatic complexity and is able to adjust itself accordingly.
This way attack/input vectors that would otherwise be undetectable by non-humans are seamlessly handled by Arachni.

Moreover, Arachni yields great performance due to its asynchronous HTTP model (courtesy of Typhoeus) -- especially
when combined with a High Performance Grid setup which allows you to combine the resources of multiple nodes for lightning fast scans.
Thus, you'll only be limited by the responsiveness of the server under audit.

Finally, it is versatile enough to cover a great deal of use cases, ranging from a simple
command line scanner utility, to a global high performance grid of scanners, to a Ruby library allowing for scripted audits.

Note: Despite the fact that Arachni is mostly targeted towards web application security,
it can easily be used for general purpose scraping, data-mining, etc with the addition of custom modules.
DESCRIPTION

end
