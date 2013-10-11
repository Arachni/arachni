=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

FORM = 'form'

class Form < Arachni::Element::Base
    include Capabilities::Refreshable

    #
    # {Form} error namespace.
    #
    # All {Form} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Error

        #
        # Raised when a specified form field could not be found/does not exist.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        #
        class FieldNotFound < Error
        end
    end

    ORIGINAL_VALUES = '__original_values__'
    SAMPLE_VALUES   = '__sample_values__'

    # @return [String] the name of the input name that holds the nonce
    attr_reader :nonce_name

    # @return [Nokogiri::XML::Element]
    attr_accessor :node

    #
    # Creates a new Form element from a URL and auditable data.
    #
    # @param    [String]    url
    #   Owner URL -- URL of the page which contains the form.
    # @param    [Hash]    raw
    #   If empty, the element will be initialized without auditable inputs.
    #
    #   If a full `Hash` is passed, it will look for an actionable URL
    #   `String` in the following keys:
    #
    #   * `'href'`
    #   * `:href`
    #   * `'action'`
    #   * `:action`
    #
    #   For an method `String` in:
    #
    #   * `'method'`
    #   * `:method`
    #
    #   Method defaults to 'get'.
    #
    #   For an auditable inputs `Hash` in:
    #
    #   * `'inputs'`
    #   * `:inputs`
    #   * `'auditable'`
    #
    #   these should contain inputs in `name => value` pairs.
    #
    def initialize( url, raw = {} )
        super( url, raw )

        was_opts_hash = false
        begin
            self.action = @raw['action'] || @raw[:action] || @raw['attrs']['action']
            was_opts_hash = true
        rescue
            self.action = self.url
        end

        begin
            self.method = @raw['method'] || @raw[:method] || @raw['attrs']['method']
            was_opts_hash = true
        rescue
            self.method = 'get'
        end

        if !was_opts_hash && (@raw.keys & [:inputs, 'inputs', 'auditable']).empty?
            self.auditable = @raw
        else
            self.auditable = @raw[:inputs] || @raw['inputs'] || simple['auditable']
        end

        self.auditable ||= {}

        @orig = self.auditable.dup
        @orig.freeze
    end

    def to_html
        return if !node
        node.to_html
    end

    #
    # @example
    #    p f = Form.from_document( 'http://stuff.com', '<form name="stuff"></form>' ).first
    #    #=> #<Arachni::Element::Form:0x00000001ddfa08 @raw={"attrs"=>{"name"=>"stuff", "action"=>"http://stuff.com/", "method"=>"get"}, "textarea"=>[], "input"=>[], "select"=>[], "auditable"=>[]}, @url="http://stuff.com/", @hash=1935432807676141374, @opts={}, @action="http://stuff.com/", @method="get", @auditable={}, @orig={}>
    #
    #    p f.name
    #    #=> "stuff"
    #
    #    p f = Form.new( 'http://stuff.com', 'attrs' => { 'name' => 'john' } )
    #    #=> #<Arachni::Element::Form:0x00000002b46160 @raw={"attrs"=>{"name"=>"john"}}, @url="http://stuff.com/", @hash=2710248079644781147, @opts={}, @action="http://stuff.com/", @method=nil, @auditable={}, @orig={}>
    #
    #    p f.name
    #    #=> "john"
    #
    #    p Form.new( 'http://stuff.com' ).name
    #    #=> nil
    #
    # @return   [String, nil]   Name of the form, if it has one.
    #
    def name
        return if !@raw['attrs'].is_a?( Hash )
        @raw['attrs']['name']
    end

    def name_or_id
        return if !@raw['attrs'].is_a?( Hash )
        name || @raw['attrs']['id']
    end

    #
    # @example
    #    p f = Form.new( 'http://stuff.com', inputs: { name: 'value' } )
    #    #=> #<Arachni::Element::Form:0x00000002190f80 @raw={:inputs=>{:name=>"value"}}, @url="http://stuff.com/", @hash=-432844557667991308, @opts={}, @action="http://stuff.com/", @method="post", @auditable={"name"=>"value"}, @orig={"name"=>"value"}>
    #
    #    p f.action
    #    #=> "http://stuff.com/"
    #
    #    p f.method
    #    #=> "post"
    #
    #    p f.auditable.keys
    #    #=> ["name"]
    #
    #    p f.id
    #    #=> "http://stuff.com/::post::[\"name\"]"
    #
    # @return   [String]    Unique form ID.
    #
    def id
        id_from :auditable
    end

    #
    # @example
    #    ap f = Form.new( 'http://stuff.com', inputs: { name: 'value' } )
    #    #=> #<Arachni::Element::Form:0x01da8d78
    #    #     attr_accessor :action = "http://stuff.com/",
    #    #     attr_accessor :auditable = {
    #    #         "name" => "value"
    #    #     },
    #    #     attr_accessor :method = "get",
    #    #     attr_accessor :url = "http://stuff.com/",
    #    #     attr_reader :hash = -277024459210456651,
    #    #     attr_reader :opts = {},
    #    #     attr_reader :orig = {
    #    #         "name" => "value"
    #    #     },
    #    #     attr_reader :raw = {
    #    #         :inputs => {
    #    #             :name => "value"
    #    #         }
    #    #     }
    #    # >
    #
    #    p f.action
    #    #=> "http://stuff.com/"
    #
    #    p f.method
    #    #=> "post"
    #
    #    p f.auditable.keys
    #    #=> ["name"]
    #
    #    p f.id_from :auditable
    #    #=> "http://stuff.com/::post::[\"name\"]"
    #
    #    p f.id
    #    #=> "http://stuff.com/::post::[\"name\"]"
    #
    #    p f.id_from :original
    #    #=> "http://stuff.com/::post::[\"name\"]"
    #
    #    f['new-input'] = 'new value'
    #
    #    p f.id_from :auditable
    #    #=> "http://stuff.com/::post::[\"name\", \"new-input\"]"
    #
    #    p f.id
    #    #=> "http://stuff.com/::post::[\"name\", \"new-input\"]"
    #
    #    p f.id_from :original
    #    #=> "http://stuff.com/::post::[\"name\"]"
    #
    def id_from( type = :auditable )
        query_vars = parse_url_vars( self.action )
        "#{self.action.split( '?' ).first.to_s.split( ';' ).first}::" <<
            "#{self.method}::#{query_vars.merge( self.send( type ) ).keys.compact.sort.to_s}"
    end

    #
    # @example
    #    p Form.new( 'http://stuff.com', inputs: { name: 'value' } ).simple
    #    #=> {"auditable"=>{"name"=>"value"}, "attrs"=>{"method"=>"post", "action"=>"http://stuff.com/"}}
    #
    #    p Form.new( 'http://stuff.com', method: 'post', inputs: { name: 'value' } ).simple
    #    #=> {"auditable"=>{"name"=>"value"}, "attrs"=>{"method"=>'post', "action"=>"http://stuff.com/"}}
    #
    # @return   [Hash]    a simple representation of self including attributes and auditables
    #
    def simple
        form = {}

        form['auditable'] = {}
        if @raw['auditable'] && !@raw['auditable'].empty?
            @raw['auditable'].each do |item|
                next if !item['name']
                form['auditable'][item['name']] = item['value']
            end
        end

        if @raw['attrs']
            form['attrs'] = @raw['attrs']
        else
            form['attrs'] = {
                'method' => @method,
                'action' => @action
            }
        end

        if form['auditable'].empty? && @auditable && !@auditable.empty?
            form['auditable'] = @auditable
        end

        form.dup
    end

    #
    # @example
    #    mutations = Form.new( 'http://stuff.com', inputs: { name: 'value' } ).mutations( 'seed' )
    #
    #    # mutations generally have seeds injected into their auditable inputs
    #    ap mutations.first
    #    #=> <Arachni::Element::Form:0x0327fdf0
    #    #    attr_accessor :action = "http://stuff.com/",
    #    #    attr_accessor :altered = "name",
    #    #    attr_accessor :auditable = {
    #    #        "name" => "seed"
    #    #    },
    #    #    attr_accessor :auditor = nil,
    #    #    attr_accessor :method = "get",
    #    #    attr_accessor :url = "http://stuff.com/",
    #    #    attr_reader :hash = -3646163768215054761,
    #    #    attr_reader :opts = {},
    #    #    attr_reader :orig = {
    #    #        "name" => "value"
    #    #    },
    #    #    attr_reader :raw = {
    #    #        :inputs => {
    #    #            :name => "value"
    #    #        }
    #    #    }
    #    #>
    #
    #    p mutations.first.original?
    #    #=> false
    #
    #    # but forms need to also be submitted with their default values
    #    # for training purposes
    #    ap original = mutations.select { |m| m.altered == Form::ORIGINAL_VALUES }.first
    #    #=> #<Arachni::Element::Form:0x022a5a60
    #    #     attr_accessor :action = "http://stuff.com/",
    #    #     attr_accessor :altered = "__original_values__",
    #    #     attr_accessor :auditable = {
    #    #         "name" => "value"
    #    #     },
    #    #     attr_accessor :auditor = nil,
    #    #     attr_accessor :method = "get",
    #    #     attr_accessor :url = "http://stuff.com/",
    #    #     attr_reader :hash = -608155834642701428,
    #    #     attr_reader :opts = {},
    #    #     attr_reader :orig = {
    #    #         "name" => "value"
    #    #     },
    #    #     attr_reader :raw = {
    #    #         :inputs => {
    #    #             :name => "value"
    #    #         }
    #    #     }
    #    # >
    #
    #    p original.original?
    #    #=> true
    #
    # @return   [Bool]  `true` if the element has not been mutated, `false` otherwise.
    #
    def original?
        self.altered == ORIGINAL_VALUES
    end

    #
    # @example
    #    mutations = Form.new( 'http://stuff.com', inputs: { name: '' } ).mutations( 'seed' )
    #
    #    # mutations generally have seeds injected into their auditable inputs
    #    ap mutations.first
    #    #=> <Arachni::Element::Form:0x0327fdf0
    #    #    attr_accessor :action = "http://stuff.com/",
    #    #    attr_accessor :altered = "name",
    #    #    attr_accessor :auditable = {
    #    #        "name" => "seed"
    #    #    },
    #    #    attr_accessor :auditor = nil,
    #    #    attr_accessor :method = "get",
    #    #    attr_accessor :url = "http://stuff.com/",
    #    #    attr_reader :hash = -3646163768215054761,
    #    #    attr_reader :opts = {},
    #    #    attr_reader :orig = {
    #    #        "name" => "value"
    #    #    },
    #    #    attr_reader :raw = {
    #    #        :inputs => {
    #    #            :name => "value"
    #    #        }
    #    #    }
    #    #>
    #
    #    # when values are missing the inputs are filled in using sample values
    #    ap sample = mutations.select { |m| m.altered == Form::SAMPLE_VALUES }.first
    #    #=> #<Arachni::Element::Form:0x02b23020
    #    #     attr_accessor :action = "http://stuff.com/",
    #    #     attr_accessor :altered = "__sample_values__",
    #    #     attr_accessor :auditable = {
    #    #         "name" => "arachni_name"
    #    #     },
    #    #     attr_accessor :auditor = nil,
    #    #     attr_accessor :method = "get",
    #    #     attr_accessor :url = "http://stuff.com/",
    #    #     attr_reader :hash = 205637814585882034,
    #    #     attr_reader :opts = {},
    #    #     attr_reader :orig = {
    #    #         "name" => ""
    #    #     },
    #    #     attr_reader :raw = {
    #    #         :inputs => {
    #    #             :name => ""
    #    #         }
    #    #     }
    #    # >
    #
    #    p sample.sample?
    #    #=> true
    #
    #
    # @return   [Bool]
    #   `true` if the element has been populated with sample
    #   ({Module::KeyFiller}) values, `false` otherwise.
    #
    # @see Arachni::Module::KeyFiller.fill
    #
    def sample?
        self.altered == SAMPLE_VALUES
    end

    def audit_id( injection_str = '', opts = {} )
        str = if original?
                  opts[:no_auditor] = true
                  ORIGINAL_VALUES
              elsif sample?
                  opts[:no_auditor] = true
                  SAMPLE_VALUES
              else
                  injection_str
              end

        super( str, opts )
    end

    #
    # Overrides {Arachni::Element::Mutable#mutations} adding support
    # for mutations with:
    #
    # * Sample values (filled by {Arachni::Module::KeyFiller.fill})
    # * Original values
    # * Password fields requiring identical values (in order to pass
    #   server-side validation)
    #
    # @example Default
    #    ap Form.new( 'http://stuff.com', { name: '' } ).mutations( 'seed' )
    #    #=> [
    #    #    [0] #<Arachni::Element::Form:0x017a74b0
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "seed"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = -1192640691543074696,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [1] #<Arachni::Element::Form:0x0157e8c8
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "arachni_nameseed"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 1303250124082341093,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [2] #<Arachni::Element::Form:0x0157ce38
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "seed\x00"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 1320080946243198326,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [3] #<Arachni::Element::Form:0x0157aa98
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "arachni_nameseed\x00"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 460190056788056230,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [4] #<Arachni::Element::Form:0x01570890
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "__original_values__",
    #    #        attr_accessor :auditable = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 1705259843882941132,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [5] #<Arachni::Element::Form:0x0156de38
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "__sample_values__",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "arachni_name"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = -2130848815716189861,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >
    #    #]
    #
    # @example skip_orig: true
    #    ap Form.new( 'http://stuff.com', { name: '' } ).mutations( 'seed', skip_orig: true )
    #    #=> [
    #    #    [0] #<Arachni::Element::Form:0x01b7ff10
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "seed"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 629695739693886457,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [1] #<Arachni::Element::Form:0x01b42f20
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "arachni_nameseed"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = -232906949296507781,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [2] #<Arachni::Element::Form:0x01b412d8
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "seed\x00"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = -2864669958217534791,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >,
    #    #    [3] #<Arachni::Element::Form:0x01b466e8
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "name",
    #    #        attr_accessor :auditable = {
    #    #            "name" => "arachni_nameseed\x00"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 1368563420578923320,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #            "name" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #            :name => ""
    #    #        }
    #    #    >
    #    #]
    #
    # @example With mirrored password fields
    #
    #    html_form = <<-HTML
    #    <form>
    #        <input type='password' name='pasword' />
    #        <input type='password' name='password-verify'/>
    #    </form>
    #    HTML
    #
    #    ap Form.from_document( 'http://stuff.com', html_form ).first.mutations( 'seed' )
    #    #=> [
    #    #    [0] #<Arachni::Element::Form:0x03193298
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "pasword",
    #    #        attr_accessor :auditable = {
    #    #                    "pasword" => "5543!%arachni_secret",
    #    #            "password-verify" => "5543!%arachni_secret"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 2997273381350449172,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #                "attrs" => {
    #    #                "action" => "http://stuff.com/",
    #    #                "method" => "get"
    #    #            },
    #    #             "textarea" => [],
    #    #                "input" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ],
    #    #               "select" => [],
    #    #            "auditable" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ]
    #    #        }
    #    #    >,
    #    #    [1] #<Arachni::Element::Form:0x0314b628
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "password-verify",
    #    #        attr_accessor :auditable = {
    #    #                    "pasword" => "seed",
    #    #            "password-verify" => "seed"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 173670487606368134,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #                "attrs" => {
    #    #                "action" => "http://stuff.com/",
    #    #                "method" => "get"
    #    #            },
    #    #             "textarea" => [],
    #    #                "input" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ],
    #    #               "select" => [],
    #    #            "auditable" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ]
    #    #        }
    #    #    >,
    #    #    [2] #<Arachni::Element::Form:0x0314a3e0
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "password-verify",
    #    #        attr_accessor :auditable = {
    #    #                    "pasword" => "5543!%arachni_secretseed",
    #    #            "password-verify" => "5543!%arachni_secretseed"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 1194840267632333783,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #                "attrs" => {
    #    #                "action" => "http://stuff.com/",
    #    #                "method" => "get"
    #    #            },
    #    #             "textarea" => [],
    #    #                "input" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ],
    #    #               "select" => [],
    #    #            "auditable" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ]
    #    #        }
    #    #    >,
    #    #    [3] #<Arachni::Element::Form:0x0314f228
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "password-verify",
    #    #        attr_accessor :auditable = {
    #    #                    "pasword" => "seed\x00",
    #    #            "password-verify" => "seed\x00"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 1541287776305441593,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #                "attrs" => {
    #    #                "action" => "http://stuff.com/",
    #    #                "method" => "get"
    #    #            },
    #    #             "textarea" => [],
    #    #                "input" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ],
    #    #               "select" => [],
    #    #            "auditable" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ]
    #    #        }
    #    #    >,
    #    #    [4] #<Arachni::Element::Form:0x0314e058
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "password-verify",
    #    #        attr_accessor :auditable = {
    #    #                    "pasword" => "5543!%arachni_secretseed\x00",
    #    #            "password-verify" => "5543!%arachni_secretseed\x00"
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = -3700401397051376057,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #                "attrs" => {
    #    #                "action" => "http://stuff.com/",
    #    #                "method" => "get"
    #    #            },
    #    #             "textarea" => [],
    #    #                "input" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ],
    #    #               "select" => [],
    #    #            "auditable" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ]
    #    #        }
    #    #    >,
    #    #    [5] #<Arachni::Element::Form:0x03154f20
    #    #        attr_accessor :action = "http://stuff.com/",
    #    #        attr_accessor :altered = "__original_values__",
    #    #        attr_accessor :auditable = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_accessor :auditor = nil,
    #    #        attr_accessor :method = "get",
    #    #        attr_accessor :url = "http://stuff.com/",
    #    #        attr_reader :hash = 4290791575672400429,
    #    #        attr_reader :opts = {},
    #    #        attr_reader :orig = {
    #    #                    "pasword" => "",
    #    #            "password-verify" => ""
    #    #        },
    #    #        attr_reader :raw = {
    #    #                "attrs" => {
    #    #                "action" => "http://stuff.com/",
    #    #                "method" => "get"
    #    #            },
    #    #             "textarea" => [],
    #    #                "input" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ],
    #    #               "select" => [],
    #    #            "auditable" => [
    #    #                [0] {
    #    #                    "type" => "password",
    #    #                    "name" => "pasword"
    #    #                },
    #    #                [1] {
    #    #                    "type" => "password",
    #    #                    "name" => "password-verify"
    #    #                }
    #    #            ]
    #    #        }
    #    #    >
    #    #]
    #
    # @param    [String]    seed    Seed to inject.
    # @param    [Hash]      opts    Mutation options.
    # @option   opts    [Bool]  :skip_orig
    #   Whether or not to skip adding a mutation holding original values and
    #   sample values.
    #
    # @return   [Array<Form>]
    #
    # @see Capabilities::Mutable#mutations
    # @see Module::KeyFiller.fill
    #
    def mutations( seed, opts = {} )
        opts = MUTATION_OPTIONS.merge( opts )
        var_combo = super( seed, opts )

        if !opts[:skip_orig]
            # this is the original hash, in case the default values
            # are valid and present us with new attack vectors
            elem = self.dup
            elem.altered = ORIGINAL_VALUES
            var_combo << elem

            elem = self.dup
            elem.auditable = Arachni::Module::KeyFiller.fill( auditable.dup )
            elem.altered = SAMPLE_VALUES
            var_combo << elem
        end

        # if there are two password type fields in the form there's a good
        # chance that it's a 'please retype your password' thing so make sure
        # that we have a variation which has identical password values
        password_fields = auditable.keys.
            select { |input| field_type_for( input ) == 'password' }

        # mirror the password fields
        if password_fields.size == 2
            var_combo.each do |f|
                f[password_fields[0]] = f[password_fields[1]]
            end.compact
        end

        var_combo.uniq
    end

    #
    # Checks whether or not the form contains 1 or more password fields.
    #
    # @example With password
    #    html_form = <<-HTML
    #       <form>
    #            <input type='password' name='pasword' />
    #       </form>
    #    HTML
    #
    #    p Form.from_document( 'http://stuff.com', html_form ).first.requires_password?
    #    #=> true
    #
    # @example Without password
    #    html_form = <<-HTML
    #       <form>
    #            <input type='text' name='stuff' />
    #       </form>
    #    HTML
    #
    #    p Form.from_document( 'http://stuff.com', html_form ).first.requires_password?
    #    #=> false
    #
    # @return   [Bool]
    #   `true` if the form contains passwords fields, `false` otherwise.
    #
    def requires_password?
        return if !self.raw.is_a?( Hash ) || !self.raw['input'].is_a?( Array )
        self.raw['input'].select { |i| i['type'] == 'password' }.any?
    end

    #
    # @example
    #    f = Form.new( 'http://stuff.com', { nonce_input: '' } )
    #    p f.has_nonce?
    #    #=> false
    #
    #    f.nonce_name = 'nonce_input'
    #    p f.has_nonce?
    #    #=> true
    #
    # @return   [Bool]  `true` if the form contains a nonce, `false` otherwise.
    #
    def has_nonce?
        !!nonce_name
    end

    #
    # When `nonce_name` is set the value of the equivalent input will be
    # refreshed every time the form is to be submitted.
    #
    # Use only when strictly necessary because it comes with a hefty performance
    # penalty as the operation will need to be in blocking mode.
    #
    # Will raise an exception if `field_name` could not be found in the form's inputs.
    #
    # @example
    #   Form.new( 'http://stuff.com', { nonce_input: '' } ).nonce_name = 'blah'
    #   #=> #<RuntimeError: Could not find field named 'blah'.>
    #
    # @param    [String]    field_name  Name of the field holding the nonce.
    #
    # @raise    [Error::FieldNotFound]  If `field_name` is not a form input.
    #
    def nonce_name=( field_name )
        if !has_inputs?( field_name )
            fail Error::FieldNotFound, "Could not find field named '#{field_name}'."
        end
        @nonce_name = field_name
    end

    #
    # Retrieves a field type for the given field `name`.
    #
    # @example
    #    html_form = <<-HTML
    #    <form>
    #        <input type='text' name='text-input' />
    #        <input type='password' name='passwd' />
    #        <input type='hidden' name='cant-see-this' />
    #    </form>
    #    HTML
    #
    #    f = Form.from_document( 'http://stuff.com', html_form ).first
    #
    #    p f.field_type_for 'text-input'
    #    #=> "text"
    #
    #    p f.field_type_for 'passwd'
    #    #=> "password"
    #
    #    p f.field_type_for 'cant-see-this'
    #    #=> "hidden"
    #
    # @param    [String]    name    Field name.
    #
    # @return   [String]
    #
    def field_type_for( name )
        return if !@raw['auditable']

        field = @raw['auditable'].select { |f| f['name'] == name }.first
        return if !field

        field['type'].to_s.downcase
    end

    # @return   [String]    'form'
    def type
        Arachni::Element::FORM
    end

    def marshal_dump
        instance_variables.inject( {} ) do |h, iv|
            if iv == :@node
                h[iv] = instance_variable_get( iv ).to_s
            else
                h[iv] = instance_variable_get( iv )
            end

            h
        end
    end

    def marshal_load( h )
        self.node = Nokogiri::HTML( h.delete(:@node) ).css('form').first
        h.each { |k, v| instance_variable_set( k, v ) }
    end

    #
    # Extracts forms by parsing the body of an HTTP response.
    #
    # @example
    #    body = <<-HTML
    #       <form action='/submit'>
    #            <input type='text' name='text-input' />
    #       </form>
    #    HTML
    #
    #    res = Typhoeus::Response.new( effective_url: 'http://host', body: body )
    #
    #    ap Form.from_response( res ).first
    #    #=> #<Arachni::Element::Form:0x017c7788
    #    #    attr_accessor :action = "http://host/submit",
    #    #    attr_accessor :auditable = {
    #    #        "text-input" => ""
    #    #    },
    #    #    attr_accessor :method = "get",
    #    #    attr_accessor :url = "http://host/",
    #    #    attr_reader :hash = 343244616730070569,
    #    #    attr_reader :opts = {},
    #    #    attr_reader :orig = {
    #    #        "text-input" => ""
    #    #    },
    #    #    attr_reader :raw = {
    #    #            "attrs" => {
    #    #            "action" => "http://host/submit",
    #    #            "method" => "get"
    #    #        },
    #    #         "textarea" => [],
    #    #            "input" => [
    #    #            [0] {
    #    #                "type" => "text",
    #    #                "name" => "text-input"
    #    #            }
    #    #        ],
    #    #           "select" => [],
    #    #        "auditable" => [
    #    #            [0] {
    #    #                "type" => "text",
    #    #                "name" => "text-input"
    #    #            }
    #    #        ]
    #    #    }
    #    #>
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Form>]
    #
    def self.from_response( response )
        from_document( response.effective_url, response.body )
    end

    #
    # Extracts forms from an HTML document.
    #
    # @example
    #    html_form = <<-HTML
    #    <form action='/submit'>
    #        <input type='text' name='text-input' />
    #    </form>
    #    HTML
    #
    #    ap Form.from_document( 'http://stuff.com', html_form ).first
    #    #=> #<Arachni::Element::Form:0x03123600
    #    #    attr_accessor :action = "http://stuff.com/submit",
    #    #    attr_accessor :auditable = {
    #    #        "text-input" => ""
    #    #    },
    #    #    attr_accessor :method = "get",
    #    #    attr_accessor :url = "http://stuff.com/",
    #    #    attr_reader :hash = 3370163854416367834,
    #    #    attr_reader :opts = {},
    #    #    attr_reader :orig = {
    #    #        "text-input" => ""
    #    #    },
    #    #    attr_reader :raw = {
    #    #            "attrs" => {
    #    #            "action" => "http://stuff.com/submit",
    #    #            "method" => "get"
    #    #        },
    #    #         "textarea" => [],
    #    #            "input" => [
    #    #            [0] {
    #    #                "type" => "text",
    #    #                "name" => "text-input"
    #    #            }
    #    #        ],
    #    #           "select" => [],
    #    #        "auditable" => [
    #    #            [0] {
    #    #                "type" => "text",
    #    #                "name" => "text-input"
    #    #            }
    #    #        ]
    #    #    }
    #    #>
    #
    #    ap Form.from_document( 'http://stuff.com', Nokogiri::HTML( html_form ) ).first
    #    #=> #<Arachni::Element::Form:0x03123600
    #    #    attr_accessor :action = "http://stuff.com/submit",
    #    #    attr_accessor :auditable = {
    #    #        "text-input" => ""
    #    #    },
    #    #    attr_accessor :method = "get",
    #    #    attr_accessor :url = "http://stuff.com/",
    #    #    attr_reader :hash = 3370163854416367834,
    #    #    attr_reader :opts = {},
    #    #    attr_reader :orig = {
    #    #        "text-input" => ""
    #    #    },
    #    #    attr_reader :raw = {
    #    #            "attrs" => {
    #    #            "action" => "http://stuff.com/submit",
    #    #            "method" => "get"
    #    #        },
    #    #         "textarea" => [],
    #    #            "input" => [
    #    #            [0] {
    #    #                "type" => "text",
    #    #                "name" => "text-input"
    #    #            }
    #    #        ],
    #    #           "select" => [],
    #    #        "auditable" => [
    #    #            [0] {
    #    #                "type" => "text",
    #    #                "name" => "text-input"
    #    #            }
    #    #        ]
    #    #    }
    #    #>
    #
    #
    # @param    [String]    url
    #   URL of the document -- used for path normalization purposes.
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Form>]
    #
    def self.from_document( url, document )
        document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
        base_url = url
        begin
            base_url = document.search( '//base[@href]' )[0]['href']
        rescue
            base_url = url
        end
        document.search( '//form' ).map do |cform|
            next if !(form = form_from_element( base_url, cform ))
            form.url = url

            # We do it this way to remove references to parents etc.
            form.node = Nokogiri::HTML.fragment( cform.to_html ).css( 'form' ).first

            form
        end.compact
    end

    #
    # Parses an HTTP request body generated by submitting a form.
    #
    # @example Simple
    #    p Form.parse_request_body 'first_name=John&last_name=Doe'
    #    #=> {"first_name"=>"John", "last_name"=>"Doe"}
    #
    # @example Weird
    #    body = 'testID=53738&deliveryID=53618&testIDs=&deliveryIDs=&selectedRows=2' +
    #        '&event=&section=&event%3Dmanage%26amp%3Bsection%3Dexam=Manage+selected+exam'
    #    p Form.parse_request_body body
    #    #=> {"testID"=>"53738", "deliveryID"=>"53618", "testIDs"=>"", "deliveryIDs"=>"", "selectedRows"=>"2", "event"=>"", "section"=>"", "event=manage&amp;section=exam"=>"Manage selected exam"}
    #
    # @param    [String]    body
    #
    # @return   [Hash]      Parameters.
    #
    def self.parse_request_body( body )
        body.to_s.split( '&' ).inject( {} ) do |h, pair|
            name, value = pair.split( '=', 2 )
            h[decode( name.to_s )] = decode( value )
            h
        end
    end
    # @see .parse_request_body
    def parse_request_body( body )
        self.class.parse_request_body( body )
    end

    #
    # Encodes a {String}'s reserved characters in order to prepare it
    # to be included in a request body.
    #
    # #example
    #    p Form.encode "+% ;&\\=\0"
    #    #=> "%2B%25+%3B%26%5C%3D%00"
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    def self.encode( str )
        ::URI.encode( ::URI.encode( str, '+%' ).recode.gsub( ' ', '+' ), ";&\\=\0" )
    end
    # @see .encode
    def encode( str )
        self.class.encode( str )
    end

    #
    # Decodes a {String} encoded for an HTTP request's body.
    #
    # @example
    #    p Form.decode "%2B%25+%3B%26%5C%3D%5C0"
    #    #=> "+% ;&\\=\\0"
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    def self.decode( str )
        URI.decode( str.to_s.recode.gsub( '+', ' ' ) )
    end
    # @see .decode
    def decode( str )
        self.class.decode( str )
    end

    def dup
        super.tap { |f| f.nonce_name = nonce_name.dup if nonce_name }
    end

    private

    def skip?( elem )
        if elem.original? || elem.sample?
            id = elem.audit_id
            return true if audited?( id )
            audited( id )
        end
        false
    end

    def self.form_from_element( url, form )
        c_form = {}
        c_form['attrs'] = attributes_to_hash( form.attributes )

        if !c_form['attrs'] || !c_form['attrs']['action']
            action = url.to_s
        else
            action = url_sanitize( c_form['attrs']['action'] )
        end

        action = to_absolute( action.to_s, url ).to_s

        c_form['attrs']['action'] = action

        if !c_form['attrs']['method']
            c_form['attrs']['method'] = 'get'
        else
            c_form['attrs']['method'] = c_form['attrs']['method'].downcase
        end

        %w(textarea input select).each do |attr|
            c_form[attr] ||= []
            form.search( ".//#{attr}" ).each do |elem|

                elem_attrs = attributes_to_hash( elem.attributes )
                c_form[elem.name] ||= []
                if elem.name != 'select'
                    c_form[elem.name] << elem_attrs
                else
                    auditables = elem.children.map do |child|
                        h = attributes_to_hash( child.attributes )
                        h['value'] ||= child.text
                        h['options'] ||= {}
                        h
                    end

                    c_form[elem.name] << {
                        'attrs'   => elem_attrs,
                        'options' => auditables
                    }
                end
            end
        end

        # merge the form elements to make auditing easier
        c_form['auditable'] = c_form['input'] | c_form['textarea']
        c_form['auditable'] =
            merge_select_with_input( c_form['auditable'], c_form['select'] )

        new( url, c_form )
    end

    def self.attributes_to_hash( attributes )
        attributes.inject( {} ){ |h, (k, v)| h[k] = v.to_s; h }
    end

    #
    # Merges an array of form inputs with an array of form selects
    #
    # @param    [Array]  inputs
    # @param    [Array]  selects
    #
    # @return   [Array]  merged array
    #
    def self.merge_select_with_input( inputs, selects )
        selected = nil
        inputs | selects.map do |select|
            select['options'].each do |option|
                if option.include?( 'selected' )
                    selected = option['value']
                    break
                end
            end

            select['attrs']['value'] = selected || begin
                select['options'].first['value']
            rescue
            end
            select['attrs']
        end
    end

    def http_request( opts, &block )
        if (original? || sample?) && opts[:train] != false
            state = original? ? 'original' : 'sample'
            print_debug "Submitting form with #{state} values; overriding trainer option."
            opts[:train] = true
            print_debug_trainer( opts )
        end

        opts = opts.dup
        opts[:method] = self.method.downcase.to_s.to_sym

        if has_nonce?
            print_info "Refreshing nonce for '#{nonce_name}'."

            f = self.class.from_response( http.get( @url, async: false ).response ).
                    select { |f| f.auditable.keys == auditable.keys }.first

            if !f
                print_bad 'Could not refresh nonce because the form could not be found.'
            else
                nonce = f.auditable[nonce_name]

                print_info "Got new nonce '#{nonce}'."

                opts[:params][nonce_name] = nonce
                opts[:async] = false
            end
        end

        http.request( self.action, opts, &block )
    end

end
end

Arachni::Form = Arachni::Element::Form
