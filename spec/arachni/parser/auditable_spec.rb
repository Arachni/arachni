require_relative '../../spec_helper'

# we need to call the class Link because it needs to correspond
# to an audit_<type> option in Arachni::Options
class Link
    include Arachni::Parser::Element::Auditable

    attr_accessor :auditable
    attr_reader :action

    def initialize( action, inputs )
        @action = action
        @auditable = inputs
    end

    def http_request( opts )
        opts[:remove_id] = true
        self.auditor.http.get( @action, opts )
    end

end

class Auditor
    include Arachni::Module::Auditor
    include Arachni::UI::Output

    attr_reader :http

    def initialize( http )
        @http = http
    end

    def self.info
        { name: 'Link auditor' }
    end
end

describe Arachni::Parser::Element::Auditable do

    before :all do
        Arachni::UI::Output.mute!

        Arachni::Options.instance.audit_links = true

        @url      = server_url_for( :auditable )
        @auditor   = Auditor.new( Arachni::HTTP.instance )
        @auditable = Link.new( @url, 'param' => 'val' )
        @auditable.auditor = @auditor
    end

    describe :submit do
        it 'should submit the element along with its auditable inputs' do
            got_response = false
            has_submited_inputs = false

            @auditable.submit.on_complete {
                |res|
                got_response = true

                body_should = res.request.params.map { |k, v| k.to_s + v.to_s }.join( "\n" )
                has_submited_inputs = (res.body == body_should)
            }
            @auditor.http.run
            got_response.should be_true
            has_submited_inputs.should be_true
        end
    end

end
