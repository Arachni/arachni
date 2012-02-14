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

module Arachni
module Plugins

#
# Vector feed plug-in.
#
# Can be used to perform extremely specialized/narrow audits
# on a per vector/element basis.
#
# Useful for unit-testing or a gazillion other things. :)
#
# @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class VectorFeed < Arachni::Plugin::Base

    def prepare
        print_status 'Pausing the framework...'
        @framework.pause!
        print_status 'Done!'
    end

    def run
        pages = {}

        feed = if @options['file']
            IO.read( @options['file'] )
        elsif @options['yaml']
            @options['yaml']
        else
            ''
        end

        if !feed || feed.empty?
            print_bad 'The feed is empty, bailing out.'
            return
        end

        feed = YAML.load( feed )

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

        print_status "Imported #{feed.size} vectors."
        feed.each {
            |vector|

            element = nil
            begin
                exception_jail{ next if !(element = hash_to_element( vector )) }
            rescue
                next
            end

            pages[element.url] ||= Arachni::Parser::Page.new(
                code: 200,
                url: element.url
            )
            pages[element.url].instance_variable_get( "@#{element.type}s" ) << element
        }

        print_status 'Pushing the vectors to the audit queue...'
        pages.values.each { |page| @framework.push_to_page_queue( page ) }
        print_status 'Done!'
    end

    def hash_to_element( vector )
        owner = @framework.opts.url.to_s
        action = vector['action']
        inputs = vector['inputs']
        method = vector['method'] || 'get'

        type   = vector['type'] || 'link'
        type = 'form' if method == 'post'

        return if !inputs || inputs.empty?

        case type
            when Arachni::Issue::Element::LINK
                Arachni::Parser::Element::Link.new( owner,
                    action: action,
                    inputs: inputs
                )
            when Arachni::Issue::Element::FORM
                Arachni::Parser::Element::Form.new( owner,
                    method: method,
                    action: action,
                    inputs: inputs
                )
            when Arachni::Issue::Element::COOKIE
                Arachni::Parser::Element::Cookie.new( owner, inputs )
            when Arachni::Issue::Element::HEADER
                Arachni::Parser::Element::Header.new( owner, inputs )
            else
                Arachni::Parser::Element::Link.new( owner,
                    action: action,
                    inputs: inputs
                )
        end
    end

    def clean_up
        print_status 'Resuming the framework...'
        @framework.resume!
        print_status 'Done!'
    end

    def self.info
        {
            :name           => 'Vector feed',
            :description    => %q{Reads in vector data from which it creates elements to be audited.
    Can be used to perform extremely specialized/narrow audits on a per vector/element basis.
    Useful for unit-testing or a gazillion other things. :)

    Example YAML file:
-
  # default type is link which has method get
  #type: link
  action: http://localhost/~zapotek/tests/links/xss.php
  inputs:
    my_param: "my val"

-
  # if a method is post it'll default to a form type
  #type: form
  method: post
  action: http://localhost/~zapotek/tests/links/xss.php
  inputs:
    post_this: "HUA!"

# GET only
-
  type: cookie
  action: http://localhost/~zapotek/tests/links/xss.php
  inputs:
    session_id: "43434234343sddsdsds"

# GET only
-
  type: header
  action: http://localhost/~zapotek/tests/links/xss.php
  # only 1 input allowed, each header field=>value must be defined separately
  inputs:
    User-Agent: "Blah/2"

            },
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptString.new( 'yaml', [ false, 'A string of YAML serialized vectors (for configuration via RPC).' ] ),
                Arachni::OptPath.new( 'file', [ false, 'A file containing the YAML serialized vectors.' ] )
            ]
        }
    end

end

end
end
