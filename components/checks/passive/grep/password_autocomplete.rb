=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Greps pages for forms which have password fields without explicitly
# disabling auto-complete.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Checks::PasswordAutocomplete < Arachni::Check::Base

    def run
        page.forms.each do |form|
            next if !form.requires_password?
            next if form.simple[:autocomplete] == 'off'
            next if has_input_with_autocomplete_off? form

            log( proof: form.html, vector: form )
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3',

            issue:       {
                name:        %q{Password field with auto-complete},
                description: %q{
In typical form-based web applications, it is common practice for developers to
allow `autocomplete` within the HTML form to improve the usability of the page.
With `autocomplete` enabled (default) it allows the browser to cache previously
entered form values entered by the user.

For legitimate purposes, this allows the user to quickly re-enter the same data,
when completing the form multiple times.

When `autocomplete` is enabled on either/both the username password fields, this
could allow a cyber-criminal with access to the victim's computer the ability to
have the victims credentials `autocomplete` (automatically entered) as the
cyber-criminal visits the affected page.

Arachni has discovered that the response of the affected location contains a form
containing a password field that has not disabled `autocomplete`.
},
                severity:    Severity::LOW,
                remedy_guidance: %q{
The `autocomplete` value can be configured in two different locations.

The first, and most secure, location is to disable `autocomplete` attribute on
the `<form>` HTML tag.
This will therefor disable `autocomplete` for all inputs within that form.
An example of disabling `autocomplete` within the form tag is `<form autocomplete=off>`.

The second slightly less desirable option is to disable `autocomplete` attribute
for a specific `<input>` HTML tag. While this may be the less desired solution
from a security perspective, it may be preferred method for usability reasons
depending on size of the form. An example of disabling the `autocomplete`
attribute within a password input tag is `<input type=password autocomplete=off>`.
}
            },
            max_issues: 25
        }
    end

end
