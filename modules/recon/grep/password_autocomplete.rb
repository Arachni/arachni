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
# @version 0.1
#
class Arachni::Modules::PasswordAutocomplete < Arachni::Module::Base

    def run
        page.forms.each do |form|
            next if !form.requires_password?
            next if form.raw['attrs'] && form.raw['attrs']['autocomplete'] == 'off'
            next if form.raw['input'].map { |i| i['autocomplete'] == 'off' }.
                                    include?( true )

            log( var: form.name_or_id, match: form.to_html, element: Element::FORM )
        end
    end

    def self.info
        {
            name:        'Password field with auto-complete',
            description: %q{Greps pages for forms which have password fields
                without explicitly disabling auto-complete.},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
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
