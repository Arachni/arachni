=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni


#
# The namespace under which all modules exist
#
module Modules
end

module Module

#
# Arachni::Module::Manager class
#
# Holds and manages the modules and their results.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Manager < Arachni::ComponentManager

    include Arachni::UI::Output

    @@results             ||= []
    @@on_register_results ||= []
    @@issue_set           ||= Set.new
    @@do_not_store        ||= false
    @@issue_mutex         ||= Mutex.new

    #
    # @param    [Arachni::Options]  opts
    #
    def initialize( opts )
        super( opts.dir['modules'], Arachni::Modules )
        @opts = opts
    end

    #
    # Runs all modules against 'page'.
    #
    # @param    [::Arachni::Parser::Page]   page    page to audit
    # @param    [::Arachni::Framework]   framework  to be assigned to modules
    #
    def run( page, framework = nil )
        keys.each { |mod| run_one( mod, page, framework ) }
    end

    #
    # Runs a single module against 'page'.
    #
    # @param    [::Arachni::Module::Base]   mod    module to run as a class
    # @param    [::Arachni::Parser::Page]   page    page to audit
    # @param    [::Arachni::Framework]   framework  to be assigned to the module
    #
    def run_one( mod, page, framework = nil )
        mod_new = mod.new( page )
        mod_new.set_framework( framework ) if framework
        mod_new.prepare
        mod_new.run
        mod_new.clean_up
    end

    def self.on_register_results( &block )
        @@on_register_results << block
    end
    def on_register_results( &block ) self.class.on_register_results( &block ) end


    def self.do_not_store!
        @@do_not_store = true
    end
    def do_not_store!() self.class.do_not_store! end

    #
    # Class method
    #
    # Registers module results with...well..us.
    #
    # @param    [Array]
    #
    def self.register_results( results )

        @@on_register_results.each { |block| block.call( results ) }
        return if @@do_not_store


        @@issue_mutex.synchronize {
            @@results |= results
            results.each { |issue| @@issue_set << self.issue_set_id_from_issue( issue ) }
        }
    end
    def register_results( results ) self.class.register_results( results ) end

    def self.issue_set_id_from_issue( issue )
        issue_url = URI( issue.url )
        issue_url_str = issue_url.scheme + "://" + issue_url.host + issue_url.path
        return "#{issue.mod_name}:#{issue.elem}:#{issue.var}:#{issue_url_str}"
    end
    def issue_set_id_from_issue( issue ) self.class.issue_set_id_from_issue( issue ) end


    def self.issue_set_id_from_elem( mod_name, elem )
        elem_url  = URI( elem.action )
        elem_url_str  = elem_url.scheme + "://" + elem_url.host + elem_url.path

        return "#{mod_name}:#{elem.type}:#{elem.altered}:#{elem_url_str}"
    end
    def issue_set_id_from_elem( mod_name, elem ) self.class.issue_set_id_from_elem( mod_name, elem ) end

    def self.issue_set
        @@issue_mutex.synchronize {
            @@issue_set
        }
    end
    def issue_set() self.class.issue_set end

    #
    # Class method
    #
    # Gets module results
    #
    # @param    [Array]
    #
    def self.results
        @@issue_mutex.synchronize {
            @@results
        }
    end
    def results() self.class.results end

end
end
end
