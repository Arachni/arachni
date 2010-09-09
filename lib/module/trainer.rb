=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/element_db'

module Arachni
module Module

#
# Trainer module
#
# Included by {Module::Base}.<br/>
# Includes trainer methods used to updated the HTML elements in case any<br/>
# new elements appear dynamically during the audit.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
module Trainer

    include ElementDB

    #
    # This is used to train Arachni.
    #
    # It will be called to analyze every HTTP response during the audit,<br/>
    # detect any changes our input may have caused to the web app<br/>
    # and make the module aware of new attack vectors that may present themselves.
    #
    # @param    [Net::HTTPResponse]  res    the HTTP response
    # @param    [String]    url     provide a new url in case our request
    #                                 caused a redirection
    #
    def train( res, url = nil )

        opts     = Options.instance
        analyzer = Analyzer.new( opts )

        analyzer.url = @page.url.clone

        if( url )
            analyzer.url = URI( @page.url ).
            merge( URI( URI.escape( url ) ) ).to_s
        end

        links   = analyzer.get_links( res.body ).clone if opts.audit_links
        forms   = analyzer.get_forms( res.body ).clone if opts.audit_forms
        cookies = analyzer.get_cookies( res.headers_hash['Set-Cookie'].to_s ).clone

        if( url && opts.audit_links )
            links.push( {
                'href' => analyzer.url,
                'vars' => analyzer.get_link_vars( analyzer.url )
            } )
        end

        update_forms( forms ) if opts.audit_forms
        update_links( links ) if opts.audit_links
        update_cookies( cookies )

    end

end
end
end
