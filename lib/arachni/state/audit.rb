=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'forwardable'

module Arachni
class State

# Stores and provides access to the state of all audit operations performed by:
#
#   * {Check::Auditor}
#       * {Check::Auditor.audited}
#       * {Check::Auditor#audited}
#       * {Check::Auditor#audited?}
#   * {Element::Capabilities::Auditable}
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Audit
    extend ::Forwardable

    def initialize
        @collection = Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def statistics
        {
            total: size
        }
    end

    [:<<, :merge, :include?, :clear, :empty?, :any?, :size, :hash, :==].each do |method|
        def_delegator :collection, method
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/set", Marshal.dump( self ) )
    end

    def self.load( directory )
        Marshal.load( IO.binread( "#{directory}/set" ) )
    end

    private

    def collection
        @collection
    end

end

end
end
