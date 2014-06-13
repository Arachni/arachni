# coding: utf-8
=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

Gem::Specification.new do |s|
    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/version'

    s.required_ruby_version = '>= 1.9.2'

    s.name              = 'arachni'
    s.version           = Arachni::VERSION
    s.date              = Time.now.strftime( '%Y-%m-%d' )
    s.summary           = 'Arachni is a feature-full, modular, high-performance' +
        ' Ruby framework aimed towards helping penetration testers and' +
        ' administrators evaluate the security of web applications.'

    s.homepage          = 'https://www.arachni-scanner.com'
    s.email             = 'tasos.laskos@gmail.com'
    s.authors           = [ 'Tasos Laskos' ]

    s.files            += Dir.glob( 'gfx/**/**' )
    s.files            += Dir.glob( 'lib/**/**' )
    s.files            += Dir.glob( 'ui/**/**' )
    s.files            += Dir.glob( 'logs/**/**' )
    s.files            += Dir.glob( 'components/**/**' )
    s.files            += Dir.glob( 'profiles/**/**' )
    s.files            += Dir.glob( 'spec/**/**' )
    s.files            += %w(Gemfile Rakefile arachni.gemspec)
    s.test_files        = Dir.glob( 'spec/**/**' )

    s.executables       = [ 'arachni', 'arachni_rpcd_monitor', 'arachni_rpcd',
                            'arachni_rpc', 'arachni_console', 'arachni_script',
                            'arachni_multi', 'arachni_reporter', 'arachni_restore' ]

    s.extra_rdoc_files  = %w(README.md ACKNOWLEDGMENTS.md LICENSE.md
                            AUTHORS.md CHANGELOG.md CONTRIBUTORS.md
                             )

    s.rdoc_options      = [ '--charset=UTF-8' ]

    s.add_dependency 'bundler'

    # For compressing/decompressing system state archives.
    s.add_dependency 'rubyzip',           '1.1.3'

    # HTML report
    s.add_dependency 'coderay'

    s.add_dependency 'childprocess',      '0.5.3'

    # RPC serialization.
    if RUBY_PLATFORM == 'java'
        s.add_dependency 'msgpack-jruby', '1.4.0'
    else
        s.add_dependency 'msgpack',       '0.5.8'
    end

    # RPC client/server implementation.
    s.add_dependency 'arachni-rpc',       '0.2.0'

    # HTTP client.
    s.add_dependency 'typhoeus',          '0.6.8'

    # Fallback URI parsing and encoding utilities.
    s.add_dependency 'addressable',       '2.3.6'

    # E-mail plugin.
    s.add_dependency 'pony',              '1.8'

    # Printing complex objects.
    s.add_dependency 'awesome_print',     '1.2.0'

    # JSON reporter.
    s.add_dependency 'json',              '1.8.1'

    # For the Arachni console (arachni_console).
    s.add_dependency 'rb-readline',       '0.5.1'

    # Markup parsing.
    s.add_dependency 'nokogiri',          '>= 1.6.1'

    # Outputting data in table format (arachni_rpcd_monitor).
    s.add_dependency 'terminal-table',    '1.4.5'

    # Browser support for DOM/JS/AJAX analysis stuff.
    s.add_dependency 'watir-webdriver',   '0.6.9'

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
Copyright          - 2010-2014 Tasos Laskos
License            - All rights reserved

Please do not hesitate to ask for assistance (via the support portal)
or report a bug (via GitHub Issues) if you come across any problem.

MSG

    s.description = <<DESCRIPTION
Arachni is an Open Source, feature-full, modular, high-performance Ruby framework
aimed towards helping penetration testers and administrators evaluate the security
of web applications.

It is smart, it trains itself by learning from the HTTP responses it receives
during the audit process and is able to perform meta-analysis using a number of
factors in order to correctly assess the trustworthiness of results and intelligently
identify false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications,
can detect changes caused while travelling through the paths of a web application’s
cyclomatic complexity and is able to adjust itself accordingly. This way attack/input
vectors that would otherwise be undetectable by non-humans are seamlessly handled by Arachni.

Moreover, Arachni yields great performance due to its asynchronous HTTP model
(courtesy of Typhoeus) — especially when combined with a High Performance Grid
setup which allows you to combine the resources of multiple nodes for lightning
fast scans. Thus, you’ll only be limited by the responsiveness of the server under audit.

Finally, it is versatile enough to cover a great deal of use cases, ranging from
a simple command line scanner utility, to a global high performance grid of
scanners, to a Ruby library allowing for scripted audits, to a multi-user
multi-scan web collaboration platform.

**Note**: Despite the fact that Arachni is mostly targeted towards web application
security, it can easily be used for  general purpose scraping, data-mining, etc
with the addition of custom components.
DESCRIPTION

end
