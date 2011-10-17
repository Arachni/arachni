=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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

    #
    # @param    [Arachni::Options]  opts
    #
    def initialize( opts )
        super( opts.dir['modules'], Arachni::Modules )
        @opts = opts
        @@results    = []
        @@on_register_results = []
        @@issue_set  = Set.new

        @@do_not_store = false

        @@issue_mutex ||= Mutex.new
    end

    def self.on_register_results( &block )
        @@on_register_results << block
    end

    def self.do_not_store!
        @@do_not_store = true
    end

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

    def self.issue_set_id_from_issue( issue )
        issue_url = URI( issue.url )
        issue_url_str = issue_url.scheme + "://" + issue_url.host + issue_url.path
        return "#{issue.mod_name}:#{issue.elem}:#{issue.var}:#{issue_url_str}"
    end

    def self.issue_set_id_from_elem( mod_name, elem )
        elem_url  = URI( elem.action )
        elem_url_str  = elem_url.scheme + "://" + elem_url.host + elem_url.path

        return "#{mod_name}:#{elem.type}:#{elem.altered}:#{elem_url_str}"
    end

    def self.issue_set
        @@issue_mutex.synchronize {
            @@issue_set
        }
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
        @@issue_mutex.synchronize {
            @@results
        }
    end

    def results
        self.class.results
    end

end
end
end
