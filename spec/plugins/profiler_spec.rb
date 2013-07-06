require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        Arachni::Options.url = url
        framework.opts.audit :links, :forms, :cookies, :headers
    end

    it 'logs taints' do
        run
        results = actual_results
        results.size.should == 6

        eoks = 0
        results.each do |result|
            elem = result['element']

            case elem['type']

                when 'form'
                    elem['name'].should == 'myform'
                    elem['auditable']['input'].include?( result['taint'] ).should be_true

                    eoks += 1

                when 'link'
                    elem['auditable']['input'].include?( result['taint'] ).should be_true
                    eoks += 1

                when 'cookie'
                    elem['auditable'].keys.should == %w(cookie2)
                    elem['auditable'].to_s.include?( result['taint'] ).should be_true
                    eoks += 1

                when 'header'
                    next if elem['auditable'].keys == %w(Set-Cookie)
                    elem['auditable'].keys.should == %w(User-Agent)
                    elem['auditable'].to_s.include?( result['taint'] ).should be_true
                    eoks += 1
            end

            oks = 0
            result['landed'].each do |elem|

                case elem['type']
                    when 'body'
                        oks += 1

                    when 'form'
                        elem['name'].should == 'form_name'
                        elem['auditable'].keys.should == %w(blah)
                        elem['auditable'].to_s.include?( result['taint'] ).should be_true

                        oks += 1

                    when 'link'
                        elem['auditable'].keys.include?( 'name' ).should be_true
                        elem['auditable'].to_s.include?( result['taint'] ).should be_true
                        oks += 1

                    when 'cookie'
                        elem['auditable'].keys.should == %w(stuff)
                        elem['auditable'].to_s.include?( result['taint'] ).should be_true
                        oks += 1

                    when 'header'
                        next if elem['auditable'].keys == %w(Set-Cookie)
                        elem['auditable'].keys.should == %w(My-Header)
                        elem['auditable'].to_s.include?( result['taint'] ).should be_true
                        oks += 1
                end
            end

            oks.should == 5
        end

        eoks.should == 6

    end
end
