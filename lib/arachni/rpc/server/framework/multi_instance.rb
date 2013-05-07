=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require_relative 'distributor'
require_relative 'master'
require_relative 'slave'

module Arachni
class RPC::Server::Framework

#
# Holds multi-Instance methods for the {RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module MultiInstance
    include Distributor
    include Slave
    include Master

    # Make inherited methods appear like they were defined in this module,
    # this makes them visible over RPC.
    [Slave, Master].each do |mod|
        mod.public_instance_methods( false ).each do |m|
            private m
            public  m
        end
    end

    # @return   [Bool]
    #   `true` if this instance is running solo (i.e. not a member of a
    #   multi-Instance operation), `false` otherwise.
    def solo?
        !master? && !slave?
    end

    # @private
    def ignore_grid
        @ignore_grid = true
    end

    #
    # Restricts the scope of the audit to individual elements.
    #
    # @param    [Array<String>]     elements
    #   List of element IDs (as created by
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id}).
    #
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def restrict_to_elements( elements, token = nil )
        return false if master? && !valid_token?( token )
        Element::Capabilities::Auditable.restrict_to_elements( elements )
        true
    end

    #
    # Updates the page queue with the provided pages.
    #
    # @param    [Array<Arachni::Page>]     pages   List of pages.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    def update_page_queue( pages, token = nil )
        return false if master? && !valid_token?( token )
        [pages].flatten.each { |page| push_to_page_queue( page )}
        true
    end

    private

    def ignore_grid?
        !!@ignore_grid
    end

    # @return   [Boolean]
    #   `true` if `token` matches the local privilege token, `false` otherwise.
    def valid_token?( token )
        @local_token == token
    end

end
end
end
