=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Auditable
    include Arachni::Element::Capabilities::Auditable

    def submit_and_process( &block )
        # If we're operating under the context of a check switch to class-level
        # method callbacks to avoid registering multiple unique callbacks
        # for the browser jobs, thus avoiding all the context that comes with
        # closures.
        if @auditor.class.respond_to? :check_and_log
            submit( @audit_options[:submit] || {}, Auditable.audit_handle_submit_cb )
        else
            super( &block )
        end
    end

    def self.handle_submission_result( page )
        # In case of redirection or runtime scope changes.
        return if !page.parsed_url.seed_in_host? && page.scope.out?

        element = page.request.performer
        if !element.audit_options[:silent]
            element.print_status "Analyzing response ##{page.request.id} for " <<
                "#{element.type} input '#{element.affected_input_name}'" <<
                " pointing to: '#{element.audit_status_message_action}'"
        end

        Arachni::Utilities.exception_jail false do
            element.auditor.check_and_log( page, element )
        end
    end

    def self.audit_handle_submit( browser, options )
        Submittable.prepare_browser( browser, options )
        page = Submittable.submit_with_browser( browser, options )
        # Failed to submit.
        return if !page

        Auditable.handle_submission_result page
    end

    def self.audit_handle_submit_cb
        @audit_handle_submit_cb ||= Auditable.method(:audit_handle_submit)
    end

    def with_browser( *args, &block )
        auditor.with_browser( *args, &block )
    end

    def with_browser_cluster( &block )
        auditor.with_browser_cluster( &block )
    end

end

end
end
end
