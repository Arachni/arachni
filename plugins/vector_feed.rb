=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

#
# Vector feed plug-in.
#
# Can be used to perform extremely specialized/narrow audits
# on a per vector/element basis.
#
# Useful for unit-testing or a gazillion other things. :)
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::Plugins::VectorFeed < Arachni::Plugin::Base

    def prepare
        framework.pause
        print_status 'System paused.'
    end

    def run
        # if the 'vectors' option is an array at this point then someone fed
        # them to us programmatically
        if !options['vectors'].is_a? Array
            feed = if options['yaml_file']
                IO.read( options['yaml_file'] )
            elsif options['yaml_string']
                options['yaml_string']
            else
                ''
            end

            if !feed || feed.empty?
                print_bad 'The feed is empty, bailing out.'
                return
            end

            feed = YAML.load_stream( StringIO.new( feed ) ).documents.flatten

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
            feed = options['vectors']
        end

        pages = {}
        page_buffer = []
        print_status "Imported #{feed.size} vectors."
        feed.each do |obj|
            vector = obj.respond_to?( :value ) ? obj.value : obj

            begin
                exception_jail{

                    if page?( vector )
                        page_buffer << page_from_body_vector( vector )
                        next
                    end

                    next if !(element = hash_to_element( vector ))

                    pages[element.url] ||= Arachni::Parser::Page.new(
                        code: 200,
                        url: element.url
                    )

                    pages[element.url].send( "#{element.type}s" ) << element
                }
            rescue
                next
            end
        end

        pages  = pages.values
        pages |= page_buffer
        if !pages.empty?
            print_status 'Pushing the vectors to the audit queue...'
            pages.each { |page| framework.push_to_page_queue( page ) }
            print_status 'Done!'
        else
            print_bad 'Could not find any usable vectors.'
        end
    end

    def page?( vector )
        vector['type'] == 'page'
    end

    def page_from_body_vector( vector )
        Arachni::Parser::Page.new(
            code:             Integer( vector['code'] || 200 ),
            url:              vector['url'] || framework.opts.url.to_s,
            body:             vector['body'] || '',
            response_headers: vector['headers'] || {}
        )
    end

    def hash_to_element( vector )
        owner  = framework.opts.url.to_s
        action = vector['action']
        inputs = vector['inputs']
        method = vector['method'] || 'get'
        type   = vector['type'] || 'link'

        return if !inputs || inputs.empty?

        e = case type
            when Arachni::Issue::Element::LINK
                Arachni::Parser::Element::Link.new( owner,
                    action: action,
                    inputs: inputs,
                )
            when Arachni::Issue::Element::FORM
                Arachni::Parser::Element::Form.new( owner,
                    method: method,
                    action: action,
                    inputs: inputs
                )
            when Arachni::Issue::Element::COOKIE
                Arachni::Parser::Element::Cookie.new( action, inputs )
            when Arachni::Issue::Element::HEADER
                Arachni::Parser::Element::Header.new( action, inputs )
            else
                Arachni::Parser::Element::Link.new( owner,
                    action: action,
                    inputs: inputs
                )
        end
        (vector['skip'] || []).each { |i| e.immutables << i }
        e
    end

    def clean_up
        framework.resume
        print_status 'System resumed.'
    end

    def self.info
        {
            name:        'Vector feed',
            description: %q{Reads in vector data from which it creates elements to be audited.
    Can be used to perform extremely specialized/narrow audits on a per vector/element basis.

    Notes:
        * To only audit the vectors in the feed you must set the 'link-count' limit to 0 to prevent crawling.
        * Can handle multiple YAML documents.

    Example YAML file:
-
  # you can pass pages to be audited by grep modules (and JS in the future)
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            options:     [
                Options::Base.new( 'vectors', [false, ' Vector array (for configuration over RPC).'] ),
                Options::String.new( 'yaml_string', [false, 'A string of YAML serialized vectors (for configuration over RPC).'] ),
                Options::Path.new( 'yaml_file', [false, 'A file containing the YAML serialized vectors.'] )
            ]
        }
    end

end
