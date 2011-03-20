=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

Gem::Specification.new do |s|
      require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

      s.name              = "arachni"
      s.version           = Arachni::VERSION
      s.date              = Time.now.strftime('%Y-%m-%d')
      s.summary           = "Arachni is a feature-full, modular, high-performance Ruby framework aimed towards helping penetration testers and administrators evaluate the security of web applications."
      s.homepage          = "https://github.com/Zapotek/arachni"
      s.email             = "tasos.laskos@gmail.com"
      s.authors           = [ "Tasos Laskos" ]

      s.files             = %w( README.md ACKNOWLEDGMENTS.md Rakefile getoptslong.rb LICENSE.md AUTHORS.md CHANGELOG.md CONTRIBUTORS.md EXPLOITATION.md HACKING.md )
      s.files            += Dir.glob("lib/**/**")
      s.files            += Dir.glob("conf/**/**")
      s.files            += Dir.glob("metamodules/**/**")
      s.files            += Dir.glob("external/**/**")
      s.files            += Dir.glob("logs/**/**")
      s.files            += Dir.glob("modules/**/**")
      s.files            += Dir.glob("path_extractors/**/**")
      s.files            += Dir.glob("plugins/**/**")
      s.files            += Dir.glob("profiles/**/**")
      s.files            += Dir.glob("reports/**/**")
      s.executables       = [ "arachni", "arachni_xmlrpcd_monitor", "arachni_xmlrpcd", "arachni_xmlrpc", "arachni_web", "arachni_web_autostart", ]

      s.extra_rdoc_files  = %w( README.md ACKNOWLEDGMENTS.md LICENSE.md AUTHORS.md CHANGELOG.md CONTRIBUTORS.md EXPLOITATION.md HACKING.md )
      s.rdoc_options      = ["--charset=UTF-8"]

      s.add_dependency "arachni-typhoeus","~> 0.2.0.2"
      s.add_dependency "nokogiri",        "~> 1.4.4"
      s.add_dependency "awesome_print",   "~> 0.3.1"
      s.add_dependency "robots",          "~> 0.10.0"
      s.add_dependency "sys-proctable",   "~> 0.8.1"
      s.add_dependency "terminal-table",  "~> 1.4.2"
      s.add_dependency "sinatra",         "~> 0.9.2"
      s.add_dependency "datamapper",      "~> 1.0.2"
      s.add_dependency "rack_csrf",       "~> 2.1.0"
      s.add_dependency "rack-flash",      "~> 0.1.1"
      s.add_dependency "json",            "~> 1.4.6"
      s.add_dependency "dm-sqlite-adapter", "~> 1.0.2"

      s.description = <<description
        Arachni is a feature-full, modular, high-performance Ruby framework aimed towards
        helping penetration testers and administrators evaluate the security of web applications.

        Arachni is smart, it trains itself by learning from the HTTP responses it receives during the audit process.
        Unlike other scanners, Arachni takes into account the dynamic nature of web applications and can detect changes caused while travelling
        through the paths of a web application's cyclomatic complexity.
        This way attack/input vectors that would otherwise be undetectable by non-humans are seamlessly handled by Arachni.

        Finally, Arachni yields great performance due to its asynchronous HTTP model (courtesy of Typhoeus).
        Thus, you'll only be limited by the responsiveness of the server under audit and your available bandwidth.

        Note: Despite the fact that Arachni is mostly targeted towards web application security,
        it can easily be used for general purpose scraping, data-mining, etc with the addition of custom modules.
description
end
