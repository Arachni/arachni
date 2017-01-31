=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Vector feed plug-in.
#
# Can be used to perform extremely specialized/narrow audits on a per
# vector/element basis.
#
# Useful for unit-testing or a gazillion other things. :)
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::VectorFeed < Arachni::Plugin::Base

    def prepare
        # if the 'vectors' option is an array at this point then someone fed
        # them to us programmatically
        if !options[:vectors].is_a? Array
            feed = if options[:yaml_file]
                IO.read( options[:yaml_file] )
            elsif options[:yaml_string]
                options[:yaml_string]
            else
                ''
            end

            if !feed || feed.empty?
                print_bad 'The feed is empty, bailing out.'
                return
            end

            feed = YAML.load_stream( StringIO.new( feed ) ).flatten

            yaml_err = 'Invalid YAML syntax, bailing out..'
            begin
                if !feed.is_a? Array
                    print_bad yaml_err
                    return
                end
            rescue
                print_bad yaml_err
                return
            end
        else
            feed = options[:vectors]
        end

        pages = {}
        page_buffer = []
        print_status "Imported #{feed.size} vectors."
        feed.each do |obj|
            vector = (obj.respond_to?( :value ) ? obj.value : obj).my_symbolize_keys( false )

            exception_jail false do
                if page?( vector )
                    page_buffer << page_from_vector( vector )
                    next
                end

                next if !(element = hash_to_element( vector ))

                pages[element.url] ||= Page.from_data( url: element.url )
                pages[element.url].send(
                    "#{element.type}s=",
                    pages[element.url].send( "#{element.type}s" ) | [element]
                )
            end
        end

        pages  = pages.values
        pages << page_buffer
        pages.flatten!

        if !pages.empty?
            print_status 'Pushing the vectors to the audit queue...'
            pages.each { |page| framework.push_to_page_queue( page, true ) }
            print_status 'Done!'
        else
            print_bad 'Could not find any usable vectors.'
        end
    end

    def page?( vector )
        vector[:type] == 'page'
    end

    def page_from_vector( vector )
        Page.from_data(
            url:      vector[:url] || framework.options.url.to_s,
            response: {
                code:    Integer( vector[:code] || 200 ),
                body:    vector[:body]     || '',
                headers: vector[:headers]  || {}
            }
        )
    end

    def hash_to_element( vector )
        owner  = framework.options.url.to_s
        action = vector[:action]
        inputs = vector[:inputs]
        source = vector[:source].to_s
        method = vector[:method] || 'get'
        type   = (vector[:type]  || 'link').to_s

        return if (!inputs || inputs.empty?) &&
            (!(type == 'xml' || type == 'json') && !source.empty?)

        e = case type
            when Element::Link.type.to_s
                Element::Link.new(
                    url:    owner,
                    action: action,
                    inputs: inputs,
                    source: source
                )

            when Element::Form.type.to_s
                Element::Form.new(
                    url:    owner,
                    method: method,
                    action: action,
                    inputs: inputs,
                    source: source
                )

            when Element::Cookie.type.to_s
                Element::Cookie.new(
                    url:    action,
                    inputs: inputs,
                    source: source
                )

            when Element::Header.type.to_s
                Header.new( url: action, inputs: inputs )

            when Element::JSON.type.to_s
                Element::JSON.new(
                    url:    action,
                    inputs: inputs,
                    source: source
                )

            when Element::XML.type.to_s
                Element::XML.new(
                    url:    action,
                    inputs: inputs,
                    source: source
                )

            else
                Element::Link.new(
                    url:    owner,
                    action: action,
                    inputs: inputs
                )
            end

        (vector[:skip] || []).each { |i| e.immutables << i }

        e
    end

    def self.info
        {
            name:        'Vector feed',
            description: %q{
Reads in vector data from which it creates elements to be audited.
Can be used to perform extremely specialized/narrow audits on a per vector/element basis.

**Notes**:

* To only audit the vectors in the feed you must set the scope page-limit to `0` to prevent crawling.
* Can handle multiple YAML documents.

Example YAML file:

    -
      # you can pass pages to be audited by grep checks (and JS in the future)
      type: page
      url: http://localhost/
      # response code
      code: 200
      # response headers
      headers:
        Content-Type: "text/html; charset=utf-8"
      body: "HTML code goes here"

    -
      # default type is link which has method get
      #type: link
      action: http://localhost/link
      inputs:
        my_param: "my val"

    -
      # if a method is post it'll default to a form type
      type: form
      method: post
      action: http://localhost/form
      inputs:
        post_this: "HUA!"
        csrf: "my_csrf_token"
      # do not fuzz/mutate/audit the following inputs (by name obviously)
      skip:
        - csrf

    # GET only
    -
      type: cookie
      action: http://localhost/cookie
      inputs:
        session_id: "43434234343sddsdsds"

    # GET only
    -
      type: header
      action: http://localhost/header
      # only 1 input allowed, each header field=>value must be defined separately
      inputs:
        User-Agent: "Blah/2"

},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.1',
            options:     [
                Options::Object.new( :vectors,
                    description: ' Vector array (for configuration over RPC).'
                ),
                Options::String.new( :yaml_string,
                    description: 'A string of YAML serialized vectors (for configuration over RPC).'
                ),
                Options::Path.new( :yaml_file,
                    description: 'A file containing the YAML serialized vectors.'
                )
            ]
        }
    end

end
