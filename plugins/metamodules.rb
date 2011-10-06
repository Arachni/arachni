=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Namespace under which all meta modules will reside
#
module MetaModules
    class Base
        include Arachni::Module::Output

        def initialize( framework )
        end

        #
        # Called before the scan starts
        #
        def pre
        end

        #
        # Called during the scan
        #
        def mid
        end

        #
        # Called after the scan has finished
        #
        def post
        end

        def self.info
            {
                :name           => '[Meta] ' + self.name.to_s.gsub( 'Arachni::MetaModules::', '' ),
                :description    => %q{Performs high-level meta-analysis on the results of the scan
                    using abstract meta components.},
                :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
                :version        => '0.1',
            }
        end

    end
end


module Plugins

#
# Performs high-level meta-analysis on the results of the scan
# using abstract meta-modules.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class MetaModules < Arachni::Plugin::Base

    def initialize( framework, options )
        @framework = framework

        @metamanager = Arachni::ComponentManager.new( @framework.opts.dir['root'] + 'metamodules/', Arachni::MetaModules )

        # load all meta-components
        @metamanager.load( ['*'] )
        @inited = {}
        @metamanager.each {
            |name, klass|
            @inited[name] = klass.new( @framework )
        }
    end

    def prepare
        # prepare all meta modules here to give them a chance to set up their hooks
        # and callbacks to other framework interfaces.
        @inited.values.each { |meta| meta.pre }

        # we need to wait until the framework has finished running
        # in order to work with the full report
        while( @framework.running? )
            ::IO.select( nil, nil, nil, 1 )
        end

    end

    def run
        results = { }
        # run all meta-modules
        @inited.each_pair {
            |name, meta|
            if (metaresult = meta.mid) && !metaresult.empty?
                results[name] = { :results => metaresult }.merge( meta.class.info )
            end
        }

        register_results( results )
    end

    def clean_up
        # let the meta-modules clean up after themselves
        @inited.values.each { |meta| meta.post }
    end

    def self.info
        {
            :name           => 'Metamodules',
            :description    => %q{Performs high-level meta-analysis on the results of the scan using abstract meta-modules.
                Before reviewing the scan results you are strongly encouraged to take full advantage of the data gathered via meta-analysis.
                They will help you shed light into the inner workings of the web application and even caution you about possible false positives and/or inconclusive test results.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1'
        }
    end


end
end
end
