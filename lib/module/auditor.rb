=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module

#
# Auditor module
#
# Included by {Module::Base}.<br/>
# Includes audit methods.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.2
#
module Auditor

    #
    # Holds constant bitfields that describe the preferred formatting
    # of injection strings.
    #
    module Format

      #
      # Leaves the injection string as is.
      #
      STRAIGHT = 1 << 0

      #
      # Apends the injection string to the default value of the input vector.<br/>
      # (If no default value exists Arachni will choose one.)
      #
      APPEND   = 1 << 1

      #
      # Terminates the injection string with a null character.
      #
      NULL     = 1 << 2

      #
      # Prefix the string with a ';', useful for command injection modules
      #
      SEMICOLON = 1 << 3
    end

    #
    # Holds constants that describe the HTML elements to be audited.
    #
    module Element
        LINK    = Vulnerability::Element::LINK
        FORM    = Vulnerability::Element::FORM
        COOKIE  = Vulnerability::Element::COOKIE
        HEADER  = Vulnerability::Element::HEADER
    end

    #
    # Default audit options.
    #
    OPTIONS = {

        #
        # Elements to audit.
        #
        # Only required when calling {#audit}.<br/>
        # If no elements have been passed to audit it will
        # use the elements in {#self.info}.
        #
        :elements => [ Element::LINK, Element::FORM,
                       Element::COOKIE, Element::HEADER ],

        #
        # The regular expression to match against the response body.
        #
        :regexp   => nil,

        #
        # Verify the matched string with this value.
        #
        :match    => nil,

        #
        # Formatting of the injection strings.
        #
        # A new set of audit inputs will be generated
        # for each value in the array.
        #
        # Values can be OR'ed bitfields of all available constants
        # of {Auditor::Format}.
        #
        # @see  Auditor::Format
        #
        :format   => [ Format::STRAIGHT, Format::APPEND,
                       Format::NULL, Format::APPEND | Format::NULL ],

        #
        # If 'train' is set to true the HTTP response will be
        # analyzed for new elements. <br/>
        # Be carefull when enabling it, there'll be a performance penalty.
        #
        # When the Auditor submits a form with original or sample values
        # this option will be overriden to true.
        #
        :train     => false,

        #
        # Enable skipping of already audited inputs
        #
        :redundant => false,

        #
        # Make requests asynchronously
        #
        :async     => true
    }

    #
    # Provides easy access to all audit methods.
    #
    # If no elements have been specified in 'opts' it will
    # use the elements from the module's "self.info()" hash. <br/>
    # If no elements have been specified in 'opts' or "self.info()" it will
    # use the elements in {OPTIONS}. <br/>
    #
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit( injection_str, opts = { }, &block )

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = self.class.info[:elements]
        end

        if( !opts.include?( :elements) || !opts[:elements] || opts[:elements].empty? )
            opts[:elements] = OPTIONS[:elements]
        end

        opts  = OPTIONS.merge( opts )

        results = []
        opts[:elements].each {
            |elem|

            case elem

                when  Element::LINK
                    results << audit_links( injection_str, opts, &block )

                when  Element::FORM
                    results << audit_forms( injection_str, opts, &block )

                when  Element::COOKIE
                    results << audit_cookies( injection_str, opts, &block )

                when  Element::HEADER
                    results << audit_headers( injection_str, opts, &block )
                else
                    raise( 'Unknown element to audit:  ' + elem.to_s )

            end

        }

        return results.flatten
    end

    #
    # Audits HTTP header fields.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_headers( injection_str, opts = { }, &block )

        return [] if !Options.instance.audit_headers

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::HEADER
        url             = @page.url

        opts[:injected_orig] = injection_str

        results = []

        @page.headers.each{
            |headers|
            headers.auditor( self )
            headers.audit( injection_str, opts, &block )
        }

        results
    end

    #
    # Audits all the links found in the page.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_links( injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::LINK

        opts[:injected_orig] = injection_str

        results = []

        @page.links.each{
            |link|
            link.auditor( self )
            link.audit( injection_str, opts, &block )
        }

        results
    end

    #
    # Audits all the forms found in the page.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_forms( injection_str, opts = { }, &block )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::FORM

        opts[:injected_orig] = injection_str

        results = []

        @page.forms.each {
            |form|
            form.auditor( self )
            form.audit( injection_str, opts, &block )

        }

        return results
    end

    #
    # Audits page cookies.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    # @return  [Array<Hash>]  if no block has been provided the method
    #                           will return the positive results of the audit
    #
    def audit_cookies( injection_str, opts = { }, &block  )

        opts            = OPTIONS.merge( opts )
        opts[:element]  = Element::COOKIE
        url             = @page.url

        opts[:injected_orig] = injection_str

        results = []

        @page.cookies.each {
            |cookie|
            cookie.auditor( self )
            cookie.audit( injection_str, opts, &block )
        }

        results
    end

end

end
end
