=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for and logs e-mail addresses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::Emails < Arachni::Check::Base

    PATTERN = /[A-Z0-9._%+-]+(?:@|\s*\[at\]\s*)[A-Z0-9.-]+(?:\.|\s*\[dot\]\s*)[A-Z]{2,4}/i

    def self.existing_domains
        @existing_domains ||= {}
    end

    def pool
        @pool ||= Concurrent::FixedThreadPool.new( 5 )
    end

    def if_exists( email, &block )
        print_info "Verifying: #{email}"

        domain = deobfuscate( email ).split( '@', 2 ).last

        # Same domain as the current page, gets a pass.
        if page.parsed_url.host == domain
            block.call true
            return
        end

        if self.class.existing_domains.include?( domain )
            if self.class.existing_domains[domain]
                print_info "Resolved: #{domain}"
                block.call
                return
            end

            print_info "Could not resolve: #{domain}"
            return
        end

        @resolution_callbacks ||= {}
        @resolution_callbacks[domain] ||= []
        @resolution_callbacks[domain] << block

        if @resolution_callbacks[domain].size > 1
            return
        end

        pool.post do
            begin
                Resolv.getaddress domain

                print_info "Resolved: #{domain}"

                while cb = @resolution_callbacks[domain].pop
                    cb.call true
                end

                self.class.existing_domains[domain] = true
            rescue Resolv::ResolvError
                print_info "Could not resolve: #{domain}"

                @resolution_callbacks.delete domain
                self.class.existing_domains[domain] = false
            end
        end
    end

    def deobfuscate( email )
        email = email.dup
        email.gsub!( '[at]', '@' )
        email.gsub!( '[dot]', '.' )
        email.gsub!( ' ', '' )
        email
    end

    def run
        body = Element::Body.new( self.page.url ).tap { |b| b.auditor = self }

        page.body.scan( PATTERN ).flatten.uniq.compact.each do |email|
            next if audited?( email )

            if_exists email do
                log(
                    signature: PATTERN,
                    proof:     email,
                    vector:    body
                )

                audited( email )
            end
        end

        http.after_run do
            pool.shutdown
        end
    end

    def self.info
        {
            name:        'E-mail address',
            description: %q{Greps pages for disclosed e-mail addresses.},
            elements:    [ Element::Body ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3',

            issue:       {
                name:            %q{E-mail address disclosure},
                description:     %q{
Email addresses are typically found on "Contact us" pages, however, they can also
be found within scripts or code comments of the application. They are used to
provide a legitimate means of contacting an organisation.

As one of the initial steps in information gathering, cyber-criminals will spider
a website and using automated methods collect as many email addresses as possible,
that they may then use in a social engineering attack.

Using the same automated methods, Arachni was able to detect one or more email
addresses that were stored within the affected page.
},
                cwe:             200,
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{E-mail addresses should be presented in such
                    a way that it is hard to process them automatically.}
            }
        }
    end

end
