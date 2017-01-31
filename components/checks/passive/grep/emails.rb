=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for and logs e-mail addresses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::Emails < Arachni::Check::Base

    PATTERN     =
        /[A-Z0-9._%+-]+(?:@|\s*\[at\]\s*)[A-Z0-9.-]+(?:\.|\s*\[dot\]\s*)[A-Z]{2,4}/i

    MIN_THREADS = 0
    MAX_THREADS = 10

    # @return   [Hash<String, Bool>]
    #   Cached results for domain resolutions through the entire scan.
    def self.cache
        @cache ||= Concurrent::Hash.new
    end

    # @return   [Hash<String, Array<Block>]
    #   Callers waiting for the results of a resolution per domain.
    def waiting
        @waiting ||= {}
    end

    # If there are multiple checks for the same domain queue them,
    # we can perform only one and notify the rest.
    #
    # @param    [String]    domain
    # @param    [Block]    block
    #   Callback to notify, will only be called if the domain exists.
    def wait_for( domain, &block )
        waiting[domain] ||= []
        waiting[domain] << block
    end

    def pool( min_threads = nil )
        @pool ||= Concurrent::ThreadPoolExecutor.new(
            # Only spawn threads when necessary, not from the get go.
            min_threads: min_threads || MIN_THREADS,

            max_threads: MAX_THREADS,

            # No bounds on the amount of domains to be checked.
            max_queue:   0
        )
    end

    # Checks whether or not an e-mail exists by resolving the domain.
    # {#resolve} will need to be called after all callbacks have been queued.
    #
    # @param    [String]    email
    #   E-mail to check.
    # @param    [Block]    block
    #   Callback to notify, will only be called if the e-mail exists.
    def if_exists( email, &block )
        print_info "Verifying: #{email}"

        domain = deobfuscate( email ).split( '@', 2 ).last

        # Same domain as the current page, gets a pass.
        if page.parsed_url.host == domain
            block.call true
            return
        end

        # In the cache, yay!
        if self.class.cache.include?( domain )
            if self.class.cache[domain]
                print_info "Resolved: #{domain}"
                block.call
                return
            end

            print_info "Could not resolve: #{domain}"
            return
        end

        wait_for( domain, &block )
    end

    # Process the {#if_exists} queue.
    def resolve
        return if waiting.empty?

        p = pool( [waiting.size, MAX_THREADS].min )

        waiting.each do |domain, _|
            p.post do
                begin
                    Resolv.getaddress domain

                    print_info "Resolved: #{domain}"
                    self.class.cache[domain] = true
                rescue Resolv::ResolvError
                    print_info "Could not resolve: #{domain}"
                    self.class.cache[domain] = false
                end
            end
        end

        http.after_run do
            pool.shutdown
            pool.wait_for_termination

            waiting.each do |domain, callbacks|
                next if !self.class.cache[domain]

                while (cb = callbacks.pop)
                    cb.call
                end
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

        resolve
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
