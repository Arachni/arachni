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

#
# The namespace under which all modules exist
#
module Modules
end

module Module

#
# Holds and manages the modules and their results.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < Arachni::Component::Manager
    include Arachni::Utilities
    extend Arachni::Utilities

    NAMESPACE = Arachni::Modules

    @@results             ||= []
    @@issue_set           ||= Set.new
    @@do_not_store        ||= false
    @@mutex               ||= Mutex.new
    @@on_register_results_blocks ||= []

    # @param    [Arachni::Framework]  framework
    def initialize( framework )
        @framework = framework
        @opts = @framework.opts
        super( @opts.dir['modules'], NAMESPACE )
    end

    #
    # Runs all modules against 'page'.
    #
    # @param    [::Arachni::Parser::Page]   page    page to audit
    #
    def run( page )
        values.each { |mod| exception_jail( false ){ run_one( mod, page ) } }
    end

    #
    # Runs a single module against 'page'.
    #
    # @param    [::Arachni::Module::Base]   mod    module to run as a class
    # @param    [::Arachni::Parser::Page]   page    page to audit
    #
    def run_one( mod, page )
        mod_new = mod.new( page, @framework )
        mod_new.prepare
        mod_new.run
        mod_new.clean_up
    end

    def self.on_register_results( &block )
        on_register_results_blocks << block
    end
    def on_register_results( &block )
        self.class.on_register_results( &block )
    end

    def self.on_register_results_blocks
        @@on_register_results_blocks
    end
    def on_register_results_blocks
        self.class.on_register_results_blocks
    end

    def self.store?
        !@@do_not_store
    end
    def store?
        self.class.store
    end

    def self.do_not_store
        @@do_not_store = true
    end
    def do_not_store
        self.class.do_not_store
    end

    def self.store
        @@do_not_store = false
    end
    def store
        self.class.store
    end

    #
    # Registers module results with...well..us.
    #
    # @param    [Array<Arachni::Issue>] results
    #
    def self.register_results( results )
        on_register_results_blocks.each { |block| block.call( results ) }
        return if !store?

        results.each do |issue|
            self.results << issue if !self.results.include?( issue )
            issue_set    << issue_set_id_from_issue( issue )
        end
    end
    def register_results( results )
        self.class.register_results( results )
    end

    def self.issue_set_id_from_issue( issue )
        issue_url = uri_parse( issue.url )
        issue_url_str = issue_url.scheme + "://" + issue_url.host + issue_url.path

        "#{issue.mod_name}:#{issue.elem}:#{issue.var}:#{issue_url_str}"
    end
    def issue_set_id_from_issue( issue )
        self.class.issue_set_id_from_issue( issue )

    end

    def self.issue_set_id_from_elem( mod_name, elem )
        elem_url = uri_parse( elem.action )
        elem_url_str = elem_url.scheme + "://" + elem_url.host + elem_url.path

        "#{mod_name}:#{elem.type}:#{elem.altered}:#{elem_url_str}"
    end
    def issue_set_id_from_elem( mod_name, elem )
        self.class.issue_set_id_from_elem( mod_name, elem )
    end

    def self.issue_set
        mutex.synchronize { @@issue_set }
    end
    def issue_set
        self.class.issue_set
    end

    def self.mutex
        @@mutex
    end
    def mutex
        self.class.mutex
    end

    #
    # Class method
    #
    # Gets module results
    #
    # @param    [Array]
    #
    def self.results
        mutex.synchronize { @@results ||= [] }
    end
    def results
        self.class.results
    end

    def self.reset
        store
        on_register_results_blocks.clear
        issue_set.clear
        results.clear
        remove_constants( NAMESPACE )
    end
    def reset
        self.class.reset
    end

end
end
end
