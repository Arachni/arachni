require_relative '../spec_helper'

describe Arachni::Issue do
    before( :all ) do
        @issue_data = {
            name: 'Module name',
            elem: Arachni::Element::LINK,
            method: 'GET',
            description: 'Issue description',
            references: {
                'Title' => 'http://some/url'
            },
            cwe: '1',
            severity: Arachni::Issue::Severity::HIGH,
            cvssv2: '4.5',
            remedy_guidance: 'How to fix the issue.',
            remedy_code: 'Sample code on how to fix the issue',
            verification: false,
            metasploitable: 'exploit/unix/webapp/php_include',
            opts: { 'some' => 'opts' },
            mod_name: 'Module name',
            internal_modname: 'module_name',
            tags: %w(these are a few tags),
            var: 'input name',
            url: 'http://test.com/stuff/test.blah?query=blah',
            headers: {
                request: {
                    'User-Agent' => 'UA/v1'
                 },
                response: {
                     'Set-Cookie' => 'name=value'
                 }
            },
            response: 'HTML response',
            injected: 'injected string',
            id: 'This string was used to identify the vulnerability',
            regexp: /some regexp/,
            regexp_match: "string matched by '/some regexp/'"
        }
        @issue = Arachni::Issue.new( @issue_data.deep_clone )
    end

    describe Arachni::Issue::Severity do
        describe 'Arachni::Issue::Severity::HIGH' do
            it 'should return "High"' do
                Arachni::Issue::Severity::HIGH.should == 'High'
            end
        end
        describe 'Arachni::Issue::Severity::MEDIUM' do
            it 'should return "Medium"' do
                Arachni::Issue::Severity::MEDIUM.should == 'Medium'
            end
        end
        describe 'Arachni::Issue::Severity::LOW' do
            it 'should return "Low"' do
                Arachni::Issue::Severity::LOW.should == 'Low'
            end
        end
        describe 'Arachni::Issue::Severity::INFORMATIONAL' do
            it 'should return "Informational"' do
                Arachni::Issue::Severity::INFORMATIONAL.should == 'Informational'
            end
        end

        it 'should be assigned to Arachni::Severity for easy access' do
            Arachni::Severity.should == Arachni::Issue::Severity
        end
    end

    it 'should assign the values in opts to the the instance vars' do
        @issue_data.each do |k, v|
            next if [ :opts, :regexp ].include?( k )
            @issue.instance_variable_get( "@#{k}".to_sym ).should == @issue_data[k]
        end
        @issue.opts.should == { regexp: '' }.merge( @issue_data[:opts] )
        @issue.cwe_url.should == 'http://cwe.mitre.org/data/definitions/1.html'
    end

    describe '#tags' do
        it 'should return the set tags' do
            @issue.tags.should == @issue_data[:tags]
        end
        context 'when nil' do
            it 'should default to an empty array' do
                Arachni::Issue.new( url: 'http://test.com' ).tags.should == []
            end
        end
    end

    context 'when there\'s an :issue key' do
        it 'should assign its hash contents to instance vars' do
            issue = Arachni::Issue.new( issue: @issue_data )
            @issue_data.each do |k, v|
                next if [ :opts, :regexp, :mod_name ].include?( k )
                issue.instance_variable_get( "@#{k}".to_sym ).should == @issue_data[k]
            end
            issue.opts.should == { regexp: '' }.merge( @issue_data[:opts] )
            issue.cwe_url.should == 'http://cwe.mitre.org/data/definitions/1.html'
        end
    end

    describe '#url=' do
        it 'should normalize the URL before assigning it' do
            i = Arachni::Issue.new
            url = 'HttP://DomainName.com/stuff here'
            i.url = url
            i.url.should == Arachni::Module::Utilities.normalize_url( url )
        end
    end

    describe '#cwe=' do
        it 'should assign a CWE ID and CWE URL based on that ID' do
            i = Arachni::Issue.new
            i.cwe = 20
            i.cwe.should == '20'
            i.cwe_url.should == 'http://cwe.mitre.org/data/definitions/20.html'
        end
    end

    describe '#references=' do
        it 'should assign a references hash' do
            i = Arachni::Issue.new
            refs = { 'title' => 'url' }
            i.references = refs
            i.references.should == refs
        end
        context 'when nil is passed as a value' do
            it 'should revert to {}' do
                i = Arachni::Issue.new
                i.references.should == {}
                i.references = nil
                i.references.should == {}
            end
        end
    end

    describe '#regexp=' do
        it 'should assign a regexp and convert it to a string' do
            i = Arachni::Issue.new
            rxp = /test/
            i.regexp = rxp
            i.regexp.should == rxp.to_s
        end
        context 'when nil is passed as a value' do
            it 'should revert to \'\'' do
                i = Arachni::Issue.new
                i.regexp = nil
                i.regexp.should == ''
            end
        end
    end

    describe '#opts=' do
        it 'should assign an opts hash and convert the included :regexp to a string' do
            i = Arachni::Issue.new
            i.opts = { an: 'opt' }
            i.opts.should == { an: 'opt', regexp: '' }

            rxp = /test/
            i.opts = { an: 'opt', regexp: rxp }
            i.opts.should == { an: 'opt', regexp: rxp.to_s }
        end
        context 'when nil is passed as a value' do
            it 'should revert to {}' do
                i = Arachni::Issue.new
                i.opts.should == { regexp: '' }
                i.opts = nil
                i.opts.should == { regexp: '' }
            end
        end
    end

    describe '#[]' do
        it 'should act as an attr_reader' do
            @issue_data.each do |k, _|
                @issue[k].should == @issue.instance_variable_get( "@#{k}".to_sym )
            end
        end
    end

    describe '#[]=' do
        it 'should act as an attr_writer' do
            raised = false
            begin
                @issue_data.each { |k, v| @issue[k] = v }
            rescue
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#each' do
        it 'should iterate over the available instance vars' do
            @issue.each do |k, v|
                @issue[k].should == @issue.send( k )
                @issue[k].should == v
            end
        end
    end

    describe '#each_pair' do
        it 'should iterate over the available instance vars' do
            @issue.each_pair do |k, v|
                @issue[k].should == @issue.send( "#{k}" )
                @issue[k].should == v
            end
        end
    end

    describe '#to_h' do
        it 'should convert self to a Hash' do
            @issue.to_h.is_a?( Hash ).should be_true
            @issue.to_h.each do |k, v|
                next if [:unique_id, :hash, :_hash, :digest].include? k
                @issue[k].should == @issue.instance_variable_get( "@#{k}".to_sym )
                @issue[k].should == v
            end
        end
    end

    describe '#unique_id' do
        it 'should return a string uniquely identifying the issue' do
            @issue.unique_id.should ==
                "#{@issue.mod_name}::#{@issue.elem}::#{@issue.var}::http://test.com/stuff/test.blah"
        end
    end

    describe '#eql?' do
        context 'when 2 issues are equal' do
            it 'should return true' do
                @issue.eql?( @issue ).should be_true

                i = @issue.deep_clone
                i.injected = 'stuff'
                @issue.eql?( i ).should be_true
            end
        end
        context 'when 2 issues are not equal' do
            it 'should return false' do
                i = @issue.deep_clone
                i.var = 'stuff'
                @issue.eql?( i ).should be_false

                i = @issue.deep_clone
                i.url = 'http://stuff'
                @issue.eql?( i ).should be_false

                i = @issue.deep_clone
                i.mod_name = 'http://stuff'
                @issue.eql?( i ).should be_false

                i = @issue.deep_clone
                i.elem = 'stuff'
                @issue.eql?( i ).should be_false
            end
        end
    end

    describe '#hash' do
        context 'when 2 issues are equal' do
            it 'should have the same hash' do
                @issue.hash.should == @issue.hash

                i = @issue.deep_clone
                i.injected = 'stuff'
                @issue.hash.should == i.hash
            end
        end
        context 'when 2 issues are not equal' do
            it 'should return false' do
                i = @issue.deep_clone
                i.var = 'stuff'
                @issue.hash.should_not == i.hash

                i = @issue.deep_clone
                i.url = 'http://stuff'
                @issue.hash.should_not == i.hash

                i = @issue.deep_clone
                i.mod_name = 'http://stuff'
                @issue.hash.should_not == i.hash

                i = @issue.deep_clone
                i.elem = 'stuff'
                @issue.hash.should_not == i.hash
            end
        end
    end

    describe '#digest (and #_hash)' do
        it 'should return a HERX digest of the issue' do
            @issue._hash.should == Digest::SHA2.hexdigest( @issue.unique_id )
            @issue.digest.should == @issue._hash
        end
    end

    describe '#remove_instance_var' do
        it 'should remove an instance variable' do
            rxp = @issue.regexp
            rxp.should_not be_nil
            @issue.remove_instance_var( :@regexp )
            @issue.regexp.should be_nil
        end
    end

end
