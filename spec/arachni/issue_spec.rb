require 'spec_helper'

describe Arachni::Issue do
    before( :all ) do
        @issue_data = {
            name: 'Module name',
            elem: Arachni::Element::LINK,
            platform: :unix,
            platform_type: :os,
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
            opts: {
                'some' => 'opts',
                'blah' => "\xE2\x9C\x93"
            },
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
            remarks: {
                the_dude: ['Hey!']
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
            it 'returns "High"' do
                Arachni::Issue::Severity::HIGH.should == 'High'
            end
        end
        describe 'Arachni::Issue::Severity::MEDIUM' do
            it 'returns "Medium"' do
                Arachni::Issue::Severity::MEDIUM.should == 'Medium'
            end
        end
        describe 'Arachni::Issue::Severity::LOW' do
            it 'returns "Low"' do
                Arachni::Issue::Severity::LOW.should == 'Low'
            end
        end
        describe 'Arachni::Issue::Severity::INFORMATIONAL' do
            it 'returns "Informational"' do
                Arachni::Issue::Severity::INFORMATIONAL.should == 'Informational'
            end
        end

        it 'is assigned to Arachni::Severity for easy access' do
            Arachni::Severity.should == Arachni::Issue::Severity
        end
    end

    it 'recodes string data to UTF8' do
        @issue.opts['blah'].should == "\u2713"
    end

    it 'assigns the values in opts to the the instance vars' do
        @issue_data.each do |k, v|
            next if [ :opts, :regexp ].include?( k )
            @issue.instance_variable_get( "@#{k}".to_sym ).should == @issue_data[k]
        end
        @issue.opts.should == { regexp: '' }.merge( @issue_data[:opts] ).recode
        @issue.cwe_url.should == 'http://cwe.mitre.org/data/definitions/1.html'
    end

    describe '#tags' do
        it 'returns the set tags' do
            @issue.tags.should == @issue_data[:tags]
        end
        context 'when nil' do
            it 'defaults to an empty array' do
                Arachni::Issue.new( url: 'http://test.com' ).tags.should == []
            end
        end
    end

    describe '#audit?' do
        context 'when the issue was discovered by manipulating an input' do
            it 'returns true' do
                Arachni::Issue.new( issue: { var: '1' } ).audit?.should be_true
            end
        end
        context 'when the issue was logged passively' do
            it 'returns false' do
                Arachni::Issue.new.audit?.should be_false
            end
        end
    end

    describe '#recon?' do
        context 'when the issue was discovered by manipulating an input' do
            it 'returns false' do
                Arachni::Issue.new( issue: { var: '1' } ).recon?.should be_false
            end
        end
        context 'when the issue was logged passively' do
            it 'returns true' do
                Arachni::Issue.new.recon?.should be_true
            end
        end
    end

    context 'when there\'s an :issue key' do
        it 'assigns its hash contents to instance vars' do
            issue = Arachni::Issue.new( issue: @issue_data )
            @issue_data.each do |k, v|
                next if [ :opts, :regexp, :mod_name ].include?( k )
                issue.instance_variable_get( "@#{k}".to_sym ).should == @issue_data[k]
            end
            issue.opts.should == { regexp: '' }.merge( @issue_data[:opts] ).recode
            issue.cwe_url.should == 'http://cwe.mitre.org/data/definitions/1.html'
        end
    end

    describe '#url=' do
        it 'normalizes the URL before assigning it' do
            i = Arachni::Issue.new
            url = 'HttP://DomainName.com/stuff here'
            i.url = url
            i.url.should == Arachni::Module::Utilities.normalize_url( url )
        end
    end

    describe '#requires_verification?' do
        context 'when the issue requires verification' do
            it 'returns true' do
                i = Arachni::Issue.new
                i.verification = true
                i.requires_verification?.should be_true
            end
        end
        context 'when the issue does not require verification' do
            it 'returns false' do
                i = Arachni::Issue.new
                i.verification = false
                i.requires_verification?.should be_false
            end
        end
        context 'by default' do
            it 'returns false' do
                i = Arachni::Issue.new
                i.requires_verification?.should be_false
            end
        end
    end

    describe '#trusted?' do
        context 'when the issue requires verification' do
            it 'returns false' do
                i = Arachni::Issue.new
                i.verification = true
                i.trusted?.should be_false
            end
        end
        context 'when the issue does not require verification' do
            it 'returns true' do
                i = Arachni::Issue.new
                i.verification = false
                i.trusted?.should be_true
            end
        end
        context 'by default' do
            it 'returns true' do
                i = Arachni::Issue.new
                i.trusted?.should be_true
            end
        end
    end

    describe '#untrusted?' do
        context 'when the issue requires verification' do
            it 'returns true' do
                i = Arachni::Issue.new
                i.verification = true
                i.untrusted?.should be_true
            end
        end
        context 'when the issue does not require verification' do
            it 'returns false' do
                i = Arachni::Issue.new
                i.verification = false
                i.untrusted?.should be_false
            end
        end
        context 'by default' do
            it 'returns false' do
                i = Arachni::Issue.new
                i.untrusted?.should be_false
            end
        end
    end


    describe '#cwe=' do
        it 'assigns a CWE ID and CWE URL based on that ID' do
            i = Arachni::Issue.new
            i.cwe = 20
            i.cwe.should == '20'
            i.cwe_url.should == 'http://cwe.mitre.org/data/definitions/20.html'
        end
    end

    describe '#references=' do
        it 'assigns a references hash' do
            i = Arachni::Issue.new
            refs = { 'title' => 'url' }
            i.references = refs
            i.references.should == refs
        end
        context 'when nil is passed as a value' do
            it 'falls-back to an empty Hash' do
                i = Arachni::Issue.new
                i.references.should == {}
                i.references = nil
                i.references.should == {}
            end
        end
    end

    describe '#regexp=' do
        it 'assigns a regexp and convert it to a string' do
            i = Arachni::Issue.new
            rxp = /test/
            i.regexp = rxp
            i.regexp.should == rxp.to_s
        end
        context 'when nil is passed as a value' do
            it 'falls-back to an empty string' do
                i = Arachni::Issue.new
                i.regexp = nil
                i.regexp.should == ''
            end
        end
    end

    describe '#opts=' do
        it 'assigns an opts hash and convert the included :regexp to a string' do
            i = Arachni::Issue.new
            i.opts = { an: 'opt' }
            i.opts.should == { an: 'opt', regexp: '' }

            rxp = /test/
            i.opts = { an: 'opt', regexp: rxp }
            i.opts.should == { an: 'opt', regexp: rxp.to_s }
        end
        context 'when nil is passed as a value' do
            it 'falls-back to an empty Hash' do
                i = Arachni::Issue.new
                i.opts.should == { regexp: '' }
                i.opts = nil
                i.opts.should == { regexp: '' }
            end
        end
    end

    describe '#remarks' do
        it 'returns the set remarks as a Hash' do
            @issue.remarks.should == @issue_data[:remarks]
        end
        context 'when uninitialised' do
            it 'falls-back to an empty Hash' do
                i = Arachni::Issue.new
                i.remarks.should == {}
            end
        end
    end

    describe '#add_remark' do
        it 'adds a remark' do
            author  = :dude
            remarks = ['Hey dude!', 'Hey again dude!' ]

            i = Arachni::Issue.new
            i.add_remark author, remarks.first
            i.add_remark author, remarks[1]

            i.remarks.should == { author => remarks }
        end

        context 'when an argument is blank' do
            it 'raises an ArgumentError' do
                i = Arachni::Issue.new

                raised = false
                begin
                    i.add_remark '', 'ddd'
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    i.add_remark :dsds, ''
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    i.add_remark '', ''
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    i.add_remark nil, nil
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true
            end
        end

    end

    describe '#[]' do
        it 'acts as an attr_reader' do
            @issue_data.each do |k, _|
                @issue[k].should == @issue.instance_variable_get( "@#{k}".to_sym )
            end
        end
    end

    describe '#[]=' do
        it 'acts as an attr_writer' do
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
        it 'iterates over the available instance vars' do
            @issue.each do |k, v|
                @issue[k].should == @issue.send( k )
                @issue[k].should == v
            end
        end
    end

    describe '#each_pair' do
        it 'iterates over the available instance vars' do
            @issue.each_pair do |k, v|
                @issue[k].should == @issue.send( "#{k}" )
                @issue[k].should == v
            end
        end
    end

    describe '#to_h' do
        it 'converts self to a Hash' do
            @issue.to_h.is_a?( Hash ).should be_true
            @issue.to_h.each do |k, v|
                next if [:unique_id, :hash, :_hash, :digest].include? k
                @issue[k].should == @issue.instance_variable_get( "@#{k}".to_sym )
                @issue[k].should == v
            end
        end
    end

    describe '#unique_id' do
        it 'returns a string uniquely identifying the issue' do
            @issue.unique_id.should ==
                "#{@issue.mod_name}::#{@issue.elem}::#{@issue.var}::http://test.com/stuff/test.blah"
        end
    end

    describe '#eql?' do
        context 'when 2 issues are equal' do
            it 'returns true' do
                @issue.eql?( @issue ).should be_true

                i = @issue.deep_clone
                i.injected = 'stuff'
                @issue.eql?( i ).should be_true
            end
        end
        context 'when 2 issues are not equal' do
            it 'returns false' do
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
            it 'have the same hash' do
                @issue.hash.should == @issue.hash

                i = @issue.deep_clone
                i.injected = 'stuff'
                @issue.hash.should == i.hash
            end
        end
        context 'when 2 issues are not equal' do
            it 'returns false' do
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
        it 'returns a HEX digest of the issue' do
            @issue._hash.should == Digest::SHA2.hexdigest( @issue.unique_id )
            @issue.digest.should == @issue._hash
        end
    end

    describe '#remove_instance_var' do
        it 'removes an instance variable' do
            rxp = @issue.regexp
            rxp.should_not be_nil
            @issue.remove_instance_var( :@regexp )
            @issue.regexp.should be_nil
        end
    end

end
