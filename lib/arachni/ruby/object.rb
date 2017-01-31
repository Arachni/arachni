=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Overloads the {Object} class providing a {#deep_clone} method.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Object

    # Deep-clones self using a Marshal dump-load.
    #
    # @return   [Object]
    #   Duplicate of self.
    def deep_clone
        Marshal.load( Marshal.dump( self ) )
    end

    def rpc_clone
        if self.class.respond_to?( :from_rpc_data )
            self.class.from_rpc_data(
                Arachni::RPC::Serializer.serializer.load(
                    Arachni::RPC::Serializer.serializer.dump( to_rpc_data_or_self )
                )
            )
        else
            Arachni::RPC::Serializer.serializer.load(
                Arachni::RPC::Serializer.serializer.dump( self )
            )
        end
    end

    def to_rpc_data_or_self
        respond_to?( :to_rpc_data ) ? to_rpc_data : self
    end

end
