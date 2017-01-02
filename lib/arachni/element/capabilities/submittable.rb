=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Capabilities::Submittable

    def initialize( options )
        super
        self.method ||= options[:method] || :get
        self.action ||= options[:action] || self.url
    end

    # @return   [Platform]
    #   Applicable platforms for the {#action} resource.
    def platforms
        Platform::Manager[@action]
    end

    # Should represent a method in {Arachni::Check::HTTP}.
    #
    # Ex. get, post, cookie, header
    #
    # @see Arachni::Check::HTTP
    #
    # @return   [Symbol]
    #   HTTP request method for the element.
    def method( *args )
        return super( *args ) if args.any?
        @method.freeze
    end
    alias :http_method :method

    # @see #method
    def method=( method )
        @method = method.to_s.downcase.to_sym
    end
    alias :http_method= :method=

    # @note Ex. 'href' for links, 'action' for forms, etc.
    #
    # @return  [String]
    #   URI to which the element points and should be audited against.
    def action
        @action.freeze
    end

    # @see #action
    def action=( url )
        @action = self.url ? to_absolute( url, self.url ) : normalize_url( url )
    end

    # @note Sets `self` as the {HTTP::Request#performer}.
    #
    # Submits `self` to the {#action} URL with the appropriate
    # {Capabilities::Inputtable#inputs parameters}.
    #
    # @param  [Hash]  options
    # @param  [Block]  block
    #   Callback to be passed the {HTTP::Response}.
    #
    # @see #http_request
    def submit( options = {}, &block )
        options                   = options.dup
        options[:parameters]      = @inputs.dup
        options[:follow_location] = true if !options.include?( :follow_location )

        @auditor ||= options.delete( :auditor )

        options[:performer] ||= self

        options[:raw_parameters] ||= raw_inputs

        http_request( options, &block )
    end

    # Must be implemented by the including class and perform the appropriate
    # HTTP request (get/post/whatever) for the current element.
    #
    # Invoked by {#submit} to submit the object.
    #
    # @param    [Hash]      opts
    # @param    [Block]     block
    #   Callback to be passed the HTTP response.
    #
    # @return   [HTTP::Request]
    #
    # @see #submit
    # @abstract
    def http_request( opts, &block )
        fail NotImplementedError
    end

    # @return   [Arachni::HTTP]
    def http
        HTTP::Client
    end

    # @note Differences in input values will be taken into consideration.
    #
    # @return  [String]
    #   String uniquely identifying self.
    def id
        "#{type}:#{method}:#{action}:#{inputtable_id}"
    end

    def dup
        new = super
        new.method = self.method
        new.action = self.action
        new
    end

    def to_h
        (defined?( super ) ? super : {}).merge(
            url:    url,
            action: action,
            method: method
        )
    end

end
end
end
