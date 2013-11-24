=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Plugins::SpiderHook < Arachni::Plugin::Base

    is_distributable

    def prepare
        framework.pause
        @urls = []
    end

    def run
        spider.on_each_page { |page| @urls << page.url }
    end

    def clean_up
        framework.resume
        wait_while_framework_running
        sleep 1 # emulate some latency to catch race conditions
        register_results( framework.self_url => @urls )
    end

    def self.merge( results )
        results.inject( {} ) { |h, r| h.merge!( r ); h }
    end

    def self.info
        {
            name:        'SpiderHook',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1'
        }
    end

end
