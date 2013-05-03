require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    def url
        web_server_url_for( name_from_filename ) + '/'
    end

    context 'when malicious requests are' do
        context 'being rejected' do
            it 'logs that a WAF exists' do
                options.url = "#{url}positive"
                run
                results_for( name_from_filename ).should == {
                    code: 1, msg: framework.plugins[name_from_filename]::MSG_FOUND
                }
            end
        end

        context 'being accepted' do
            it 'does log a WAF' do
                options.url = "#{url}negative"
                run
                results_for( name_from_filename ).should == {
                    code: 0, msg: framework.plugins[name_from_filename]::MSG_NOT_FOUND
                }
            end
        end
    end

    context 'when the webapp behaves erratically' do
        it 'logs that the tests were inconclusive' do
            options.url = "#{url}inconclusive"
            run
            results_for( name_from_filename ).should == {
                code: -1, msg: framework.plugins[name_from_filename]::MSG_INCONCLUSIVE
            }
        end
    end
end
