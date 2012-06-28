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
    @@on_register_results_blocks ||= []
    @@on_register_results_blocks_raw ||= []

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

    def self.on_register_results_raw( &block )
        on_register_results_blocks_raw << block
    end
    def on_register_results_raw( &block )
        self.class.on_register_results_raw( &block )
    end

    def self.on_register_results_blocks_raw
        @@on_register_results_blocks_raw
    end
    def on_register_results_blocks_raw
        self.class.on_register_results_blocks_raw
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
    # De-duplicates and registers module results (issues).
    #
    # @param    [Array<Arachni::Issue>] results
    #
    # @return   [Integer]   amount of (unique) issues registered
    #
    def self.register_results( results )
        on_register_results_blocks_raw.each { |block| block.call( results ) }

        unique = dedup( results )
        return 0 if unique.empty?

        unique.each { |issue| issue_set << issue.unique_id if issue.var }

        on_register_results_blocks.each { |block| block.call( unique ) }
        return 0 if !store?

        unique.each { |issue| self.results << issue }
        unique.size
    end
    def register_results( results )
        self.class.register_results( results )
    end

    def self.issue_set
        @@issue_set
    end
    def issue_set
        self.class.issue_set
    end

    #
    # Class method
    #
    # Gets module results
    #
    # @param    [Array]
    #
    def self.results
        @@results ||= []
    end
    def results
        self.class.results
    end

    def self.reset
        store
        on_register_results_blocks.clear
        on_register_results_blocks_raw.clear
        issue_set.clear
        results.clear
        remove_constants( NAMESPACE )
    end
    def reset
        self.class.reset
    end

    def self.dedup( issues )
        issues.uniq.reject { |issue| issue_set.include?( issue.unique_id ) }
    end
    def dedup( issues )
        self.class.dedup( issues )
    end

end
end
end
