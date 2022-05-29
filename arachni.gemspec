# coding: utf-8
=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

Gem::Specification.new do |s|
    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/version'

    s.required_ruby_version = '>= 2.3.0'

    s.name              = 'arachni'
    s.version           = Arachni::VERSION
    s.date              = Time.now.strftime( '%Y-%m-%d' )
    s.summary           = 'Arachni is a feature-full, modular, high-performance' +
        ' Ruby framework aimed towards helping penetration testers and' +
        ' administrators evaluate the security of web applications.'

    s.homepage          = 'https://www.arachni-scanner.com'
    s.email             = 'tasos.laskos@arachni-scanner.com'
    s.authors           = [ 'Tasos Laskos' ]
    s.licenses          = ['Arachni Public Source License v1.0']

    s.files            += Dir.glob( 'config/**/**' )
    s.files            += Dir.glob( 'gfx/**/**' )
    s.files            += Dir.glob( 'lib/**/**' )
    s.files            += Dir.glob( 'ui/**/**' )
    s.files            += Dir.glob( 'logs/**/**' )
    s.files            += Dir.glob( 'components/**/**' )
    s.files            += Dir.glob( 'profiles/**/**' )
    s.files            += Dir.glob( 'spec/**/**' )
    s.files            += %w(Gemfile Rakefile arachni.gemspec)
    s.test_files        = Dir.glob( 'spec/**/**' )

    s.executables       = Dir.glob( 'bin/*' ).map { |e| File.basename e }

    s.extra_rdoc_files  = %w(README.md LICENSE.md CHANGELOG.md)

    s.rdoc_options      = [ '--charset=UTF-8' ]

    s.add_dependency 'awesome_print',       '1.6.1'

    s.add_dependency 'rack',                '2.2.3.1'
    s.add_dependency 'rack-test'

    # Don't specify version, messes with the packages since they always grab the
    # latest one.
    s.add_dependency 'bundler'

    s.add_dependency 'concurrent-ruby',     '1.0.5'
    s.add_dependency 'concurrent-ruby-ext', '1.0.5'

    # For compressing/decompressing system state archives.
    s.add_dependency 'rubyzip',             '>= 1.3.0'

    # HTTP proxy server
    s.add_dependency 'http_parser.rb',      '0.6.0'

    # HTML report
    s.add_dependency 'coderay',             '1.1.2'

    s.add_dependency 'childprocess',        '0.9.0'

    # RPC serialization.
    s.add_dependency 'msgpack',             '1.2.4'

    if RUBY_PLATFORM != 'java'
        # Optimized JSON.
        s.add_dependency 'oj',              '3.6.5'
        s.add_dependency 'oj_mimic_json',   '1.0.1'
    end

    # Web server
    s.add_dependency 'puma',                '>= 4.3.9'

    # REST API
    s.add_dependency 'sinatra',             '2.2.0'
    s.add_dependency 'sinatra-contrib',     '2.2.0'

    # RPC client/server implementation.
    s.add_dependency 'arachni-rpc',         '~> 0.2.1.4'

    # HTTP client.
    s.add_dependency 'typhoeus',            '1.3.0'

    # Fallback URI parsing and encoding utilities.
    s.add_dependency 'addressable',         '>= 2.8.0'

    # E-mail plugin.
    s.add_dependency 'pony',                '1.12'

    # For the Arachni console (arachni_console).
    s.add_dependency 'rb-readline',         '0.5.5'

    # Markup parsing, for reports and Element::XML.
    s.add_dependency 'nokogiri'
    # Really fast and lightweight markup parsing, for pages.
    s.add_dependency 'ox',                  '2.9.4'

    # Outputting data in table format (arachni_rpcd_monitor).
    s.add_dependency 'terminal-table',      '1.8.0'

    # Browser support for DOM/JS/AJAX analysis stuff.
    s.add_dependency 'watir',               '6.19.1'
    s.add_dependency 'selenium-webdriver',  '4.1.0'

    # Markdown to HTML conversion, used by the HTML report for component
    # descriptions.
    s.add_dependency 'kramdown',            '>= 2.3.0'

    # Used to scrub Markdown for XSS etc.
    s.add_dependency 'loofah',              '>= 2.3.1'

    s.post_install_message = <<MSG

Thank you for installing Arachni, here are some resources which should
help you make the best of it:

Homepage           - http://arachni-scanner.com
Blog               - http://arachni-scanner.com/blog
Documentation      - http://arachni-scanner.com/wiki
Support            - http://support.arachni-scanner.com
GitHub page        - http://github.com/Arachni/arachni
Code Documentation - http://rubydoc.info/github/Arachni/arachni
License            - Arachni Public Source License v1.0
                        (https://github.com/Arachni/arachni/blob/master/LICENSE.md)
Author             - Tasos "Zapotek" Laskos (http://twitter.com/Zap0tek)
Twitter            - http://twitter.com/ArachniScanner
Copyright          - 2010-2022 Ecsypno (http://www.ecsypno.com)

Please do not hesitate to ask for assistance (via the support portal)
or report a bug (via GitHub Issues) if you come across any problem.

MSG

    s.description = <<DESCRIPTION
Arachni is a feature-full, modular, high-performance Ruby framework aimed towards
helping penetration testers and administrators evaluate the security of web applications.

It is smart, it trains itself by monitoring and learning from the web application's
behavior during the scan process and is able to perform meta-analysis using a number of
factors in order to correctly assess the trustworthiness of results and intelligently
identify (or avoid) false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications,
can detect changes caused while travelling through the paths of a web application’s
cyclomatic complexity and is able to adjust itself accordingly. This way, attack/input
vectors that would otherwise be undetectable by non-humans can be handled seamlessly.

Moreover, due to its integrated browser environment, it can also audit and inspect
client-side code, as well as support highly complicated web applications which make
heavy use of technologies such as JavaScript, HTML5, DOM manipulation and AJAX.

Finally, it is versatile enough to cover a great deal of use cases, ranging from
a simple command line scanner utility, to a global high performance grid of
scanners, to a Ruby library allowing for scripted audits, to a multi-user
multi-scan web collaboration platform.
DESCRIPTION

end
