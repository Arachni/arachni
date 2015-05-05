=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.lib + 'issue/severity'

# Represents a detected issue.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Issue

    # Attributes removed from a parent issue (i.e. an issues with variations)
    # and solely populating variations.
    VARIATION_ATTRIBUTES = Set.new([
        :@page, :@referring_page, :@proof, :@signature, :@remarks, :@trusted
    ])

    # @return    [String]
    #   Name.
    attr_accessor :name

    # @note Should be treated as Markdown.
    #
    # @return    [String]
    #   Brief description.
    attr_accessor :description

    # @note Should be treated as Markdown.
    #
    # @return    [String]
    #   Brief text explaining how to remedy the issue.
    attr_accessor :remedy_guidance

    # @return    [String]
    #   Code snippet demonstrating how to remedy the Issue.
    attr_accessor :remedy_code

    # @return    [String]
    #   Severity of the issue.
    #
    # @see Severity
    attr_accessor :severity

    # @return [Array<String>]
    #   Tags categorizing the issue.
    attr_accessor :tags

    # @return    [Hash]
    #   References related to the issue.
    attr_accessor :references

    # @return    [String]
    #   The CWE ID number of the issue.
    #
    # @see http://cwe.mitre.org/
    attr_accessor :cwe

    # @return    [Symbol]
    #   Name of the vulnerable platform.
    #
    # @see Platform::Manager
    attr_accessor :platform_name

    # @return    [Symbol]
    #   Type of the vulnerable platform.
    #
    # @see Platform::Manager
    attr_accessor :platform_type

    # @return    [Element::Base, nil]
    #   Instance of the relevant vector if available.
    attr_accessor :vector

    # @return   [Page]
    #   Page containing the {#vector} and whose audit resulted in the discovery
    #   of the issue.
    attr_accessor :referring_page

    # @return   [Page]
    #   Page proving the issue.
    attr_accessor :page

    # @return   [Hash]
    #   {Check::Base.info Information} about the check that logged the issue.
    attr_accessor :check

    # @return    [String]
    #   The signature/pattern that identified the issue.
    attr_accessor :signature

    # @return    [String]
    #   Data that was matched by the {#signature}.
    attr_accessor :proof

    # @return   [Bool]
    #   `true` if the issue can be trusted (doesn't require manual verification),
    #   `false` otherwise.
    attr_accessor :trusted

    # @return [Hash]
    #   Remarks about the issue. Key is the name of the entity which
    #   made the remark, value is an `Array` of remarks.
    attr_accessor :remarks

    # @return   [Array<Issue>]
    #   Variations of this issue.
    attr_accessor :variations

    # @return   [Issue,nil]
    #   Parent of variation.
    attr_accessor :parent

    # @param    [Hash]    options
    #   Configuration hash holding instance attributes.
    def initialize( options = {} )
        # Make sure we're dealing with UTF-8 data.
        options = options.recode

        options.each do |k, v|
            send( "#{k.to_s.downcase}=", v )
        end

        fail ArgumentError, 'Missing :vector' if !@vector

        @remarks    ||= {}
        @trusted      = true if @trusted.nil?
        @references ||= {}
        @tags       ||= []
        @variations ||= []
        @variation    = nil
        @parent       = nil
    end

    # @note The whole environment needs to be fresh.
    #
    # Rechecks the existence of this issue.
    #
    # @param    [Framework.nil]     framework
    #   {Framework} to use, if `nil` is given a new {Framework} will be
    #   instantiated and used.
    #
    # @return   [Issue,nil]
    #   Fresh {Issue} if the issue still exists, `nil` otherwise.
    def recheck( framework = nil )
        original_options = Options.to_h

        new_issue = nil
        checker = proc do |f|
            if active?
                referring_page.update_element_audit_whitelist vector
                f.options.audit.elements vector.class.type
                f.options.audit.include_vector_patterns = [affected_input_name]
            end

            f.options.url = referring_page.url

            f.checks.load( parent ? parent.check[:shortname] : check[:shortname] )
            f.push_to_page_queue referring_page

            f.options.scope.do_not_crawl

            f.run

            new_issue = Data.issues[digest]
        end

        if framework
            checker.call framework
        else
            Framework.new( &checker )
        end

        new_issue
    ensure
        Options.reset
        Options.set original_options
    end

    # @return   [HTTP::Response]
    def response
        return if !page
        page.response
    end

    # @return   [HTTP::Request]
    def request
        return if !response
        response.request
    end

    # Adds a remark as a heads-up to the end user.
    #
    # @param    [String, Symbol]    author
    #   Component which made the remark.
    # @param    [String]    string
    #   Remark.
    def add_remark( author, string )
        fail ArgumentError, 'Author cannot be blank.' if author.to_s.empty?
        fail ArgumentError, 'String cannot be blank.' if string.to_s.empty?

        (@remarks[author] ||= []) << string
    end

    # @return   [Boolean]
    #   `true` if the issue was discovered by manipulating an input,
    #   `false` otherwise.
    #
    # @see #passive?
    def active?
        if variations && variations.any?
            return variations.first.active?
        end

        !!(vector.respond_to?( :affected_input_name ) && vector.affected_input_name)
    end

    # @return   [String, nil]
    #   The name of the affected input, `nil` if the issue is {#passive?}.
    #
    # @see #passive?
    def affected_input_name
        return if !active?

        if variations && variations.any?
            return variations.first.vector.affected_input_name
        end

        vector.affected_input_name
    end

    # @return   [Boolean]
    #   `true` if the issue was discovered passively, `false` otherwise.
    #
    # @see audit?
    def passive?
        !active?
    end

    # @return   [Bool]
    #   `true` if the issue can be trusted (doesn't require manual verification),
    #   `false` otherwise.
    #
    # @see #requires_verification?
    def trusted?
        !!@trusted
    end

    # @see #trusted?
    def untrusted?
        !trusted?
    end

    def cwe=( id )
        id = id.to_i
        return if id == 0
        @cwe = id
    end

    # @return   [String]
    #   {#cwe CWE} reference URL.
    def cwe_url
        return if !cwe
        @cwe_url ||= "http://cwe.mitre.org/data/definitions/#{cwe}.html".freeze
    end

    def references=( refs )
        @references = (refs || {}).stringify_recursively_and_freeze
    end

    [:page, :referring_page, :vector].each do |m|
        define_method "#{m}=" do |object|
            if object
                # Once the object is logged we need a deep copy of it to ensure
                # integrity.
                object = object.deep_clone
                object.prepare_for_report
            end

            instance_variable_set( "@#{m}".to_sym, object )
        end
    end

    [:name, :description, :remedy_guidance, :remedy_code, :proof, :signature].each do |m|
        define_method "#{m}=" do |s|
            instance_variable_set( "@#{m}".to_sym, s ? s.to_s.freeze : nil )
        end
    end

    # @return   [Hash]
    def to_h
        h = {}

        self.instance_variables.each do |var|
            h[normalize_name( var )] = try_dup( instance_variable_get( var ) )
        end

        h[:vector] = vector.to_h
        h.delete( :unique_id )

        if solo?
            h.delete( :variation )
        else
            if variation?
                h[:vector].delete :source
                h[:vector].delete :type
                h[:vector].delete :url
                h[:vector].delete :action
                h[:vector].delete :default_inputs
                h[:vector].delete :affected_input_name
            else
                h[:vector][:inputs] = h[:vector].delete( :default_inputs )
                h[:vector][:affected_input_name] = affected_input_name
            end
        end

        if !variation? || solo?
            h[:digest]   = digest
            h[:severity] = severity.to_sym
            h[:cwe_url]  = cwe_url if cwe_url

            # Since we're doing the whole cross-platform hash thing better switch
            # the Element classes in the check's info data to symbols.
            h[:check][:elements] ||= []
            h[:check][:elements]   = h[:check][:elements].map(&:type)

            h[:variations] = @variations.map(&:to_h)
        end

        if variation? || solo?
            if page
                dom_h = page.dom.to_h
                dom_h.delete(:skip_states)

                h[:page] = {
                    body: page.body,
                    dom:  dom_h
                }
            end

            if referring_page
                referring_page_dom_h = referring_page.dom.to_h
                referring_page_dom_h.delete(:skip_states)

                h[:referring_page] = {
                    body: referring_page.body,
                    dom:  referring_page_dom_h
                }
            end

            h[:response] = response.to_h if response
            h[:request]  = request.to_h  if request
        end

        h.delete :parent

        h
    end
    alias :to_hash :to_h

    # @return   [String]
    #   A string uniquely identifying this issue.
    def unique_id
        return @unique_id if @unique_id
        vector_info = active? ? "#{vector.method}:#{vector.affected_input_name}:" : nil
        "#{name}:#{vector_info}#{vector.action.split( '?' ).first}"
    end

    # @return   [Integer]
    #   A hash uniquely identifying this issue.
    #
    # @see #unique_id
    def digest
        unique_id.persistent_hash
    end

    # @return   [Bool]
    #   `true` if the issue neither has nor is a variation, `false` otherwise.
    def solo?
        @variation.nil?
    end

    # @return   [Bool]
    #   `true` if `self` is a variation.
    def variation?
        !!@variation
    end

    # @return   [Issue]
    #   A copy of `self` **without** {VARIATION_ATTRIBUTES specific} details
    #   and an empty array of {#variations} to be populated.
    #
    #   Also, the {#vector} attribute will hold the original, non-mutated vector.
    def with_variations
        issue = self.deep_clone

        instance_variables.each do |k|
            next if k == :@trusted || !VARIATION_ATTRIBUTES.include?( k ) ||
                !issue.instance_variable_defined?( k )

            issue.remove_instance_variable k
        end

        issue.vector.reset

        issue.unique_id = unique_id
        issue.variation = false
        issue.parent    = nil
        issue
    end

    # @return   [Issue]
    #   A copy of `self` with {VARIATION_ATTRIBUTES specific} details **only**
    #   and the mutated {#vector}.
    def as_variation
        issue = self.deep_clone

        instance_variables.each do |k|
            next if k == :@vector || VARIATION_ATTRIBUTES.include?( k ) ||
                !issue.instance_variable_defined?( k )

            issue.remove_instance_variable k
        end

        issue.unique_id = unique_id
        issue.variation = true
        issue.parent    = self
        issue
    end

    # Converts `self` to a solo issue, in place.
    #
    # @param    [Issue] issue
    #   Parent issue.
    # @return   [Issue]
    #   Solo issue, with generic vulnerability data filled in from `issue`.
    def to_solo!( issue )
        issue.instance_variables.each do |k|
            next if k == :@variations || k == :@vector || k == :@trusted
            next if (val = issue.instance_variable_get(k)).nil?
            instance_variable_set( k, val )
        end

        @variations = []
        @variation  = nil
        @parent     = nil

        self
    end

    # Copy of `self` as a solo issue.
    #
    # @param    [Issue] issue
    #   Parent issue.
    # @return   [Issue]
    #   Solo issue, with generic vulnerability data filled in from `issue`.
    def to_solo( issue )
        deep_clone.to_solo!( issue )
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        unique_id.hash
    end

    def eql?( other )
        hash == other.hash
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data = {}
        instance_variables.each do |ivar|
            next if ivar == :@parent

            data[ivar.to_s.gsub('@','')] =
                instance_variable_get( ivar ).to_rpc_data_or_self
        end

        if data['check'] && data['check'][:elements]
            data['check'] = data['check'].dup
            data['check'][:elements] = data['check'][:elements].map(&:to_s)
        end

        if data['variations']
            data['variations'] = data['variations'].map(&:to_rpc_data)
        end

        data['digest']   = digest
        data['severity'] = data['severity'].to_s

        data
    end

    # @param    [Hash]  data
    #   {#to_rpc_data}
    # @return   [Issue]
    def self.from_rpc_data( data )
        instance = allocate

        data.each do |name, value|
            value = case name
                        when 'vector'
                            element_string_to_class( value.delete('class') ).from_rpc_data( value )

                        when 'check'
                            if value['elements']
                                value['elements'] = (value['elements'].map do |class_name|
                                    element_string_to_class( class_name )
                                end)
                            end

                            value.my_symbolize_keys(false)

                        when 'variations'
                            value.map { |i| from_rpc_data i }

                        when 'remarks'
                            value.my_symbolize_keys

                        when 'platform_name', 'platform_type'
                            next if !value
                            value.to_sym

                        when 'severity'
                            next if value.to_s.empty?
                            Severity.const_get( value.upcase.to_sym )

                        when 'page', 'referring_page'
                            Arachni::Page.from_rpc_data( value )

                        else
                            value
                    end

            instance.instance_variable_set( "@#{name}", value )
        end

        if instance.variations
            instance.variations.each do |v|
                v.parent = instance
            end
        end

        instance
    end

    protected

    def self.element_string_to_class( element )
        parent = Arachni::Element
        element.gsub( "#{parent}::", '' ).split( '::' ).each do |klass|
            parent = parent.const_get( klass )
        end
        parent
    end

    def unique_id=( id )
        @unique_id = id
    end

    def variation=( bool )
        @variation = bool
    end

    private

    def normalize_name( name )
        name.to_s.gsub( /@/, '' ).to_sym
    end

    def try_dup( obj )
        obj.dup rescue obj
    end

    protected :remove_instance_variable
end
end

Arachni::Severity = Arachni::Issue::Severity
