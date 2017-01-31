=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Greps pages for forms which have password fields without explicitly
# disabling auto-complete.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::PasswordAutocomplete < Arachni::Check::Base

    def run
        page.forms.each do |form|
            next if !form.requires_password?
            next if form.simple[:autocomplete] == 'off'
            next if has_input_with_autocomplete_off? form

            log( vector: form )
        end
    end

    def has_input_with_autocomplete_off?( form )
        form.inputs.each do |k, v|
            return true if form.details_for( k )[:autocomplete] == 'off'
        end
        false
    end

    def self.info
        {
            name:        'Password field with auto-complete',
            description: %q{Greps pages for forms which have password fields
                without explicitly disabling auto-complete.},
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3.1',

            issue:       {
                name:        %q{Password field with auto-complete},
                description: %q{
In typical form-based web applications, it is common practice for developers to
allow `autocomplete` within the HTML form to improve the usability of the page.
With `autocomplete` enabled (default), the browser is allowed to cache previously
entered form values.

For legitimate purposes, this allows the user to quickly re-enter the same data
when completing the form multiple times.

When `autocomplete` is enabled on either/both the username and password fields,
this could allow a cyber-criminal with access to the victim's computer the ability
to have the victim's credentials automatically entered as the cyber-criminal
visits the affected page.

Arachni has discovered that the affected page contains a form containing a
password field that has not disabled `autocomplete`.
},
                severity:    Severity::LOW,
                remedy_guidance: %q{
The `autocomplete` value can be configured in two different locations.

The first and most secure location is to disable the `autocomplete` attribute on
the `<form>` HTML tag. This will disable `autocomplete` for all inputs within that form.
An example of disabling `autocomplete` within the form tag is `<form autocomplete=off>`.

The second slightly less desirable option is to disable the `autocomplete` attribute
for a specific `<input>` HTML tag.
While this may be the less desired solution from a security perspective, it may
be preferred method for usability reasons, depending on size of the form.
An example of disabling the `autocomplete` attribute within a password input tag
is `<input type=password autocomplete=off>`.
}
            },
            max_issues: 25
        }
    end

end
