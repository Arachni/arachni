=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Greps pages for forms which have password fields without explicitly
# disabling auto-complete.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Checks::PasswordAutocomplete < Arachni::Check::Base

    def run
        page.forms.each do |form|
            next if !form.requires_password?
            next if form.simple[:autocomplete] == 'off'
            next if has_input_with_autocomplete_off? form

            log( var: form.name_or_id, match: form.to_html, element: Element::Form )
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
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:        %q{Password field with auto-complete},
                description: %q{Some browsers automatically fill-in forms with
                    sensitive user information for fields that don't have
                    the auto-complete feature explicitly disabled.},
                severity:    Severity::LOW
            },
            max_issues: 25
        }
    end

end
