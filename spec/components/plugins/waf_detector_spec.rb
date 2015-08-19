require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    def url
        Arachni::Utilities.normalize_url web_server_url_for( component_name )
    end

    context 'when malicious requests are' do
        context 'being rejected' do
            it 'logs that a WAF exists' do
                options.url = "#{url}positive"

                run

                expect(actual_results).to eq({
                    'status'  => 'found',
                    'message' => plugin::STATUSES[:found]
                })
            end
        end

        context 'being accepted' do
            it 'does not log a WAF' do
                options.url = "#{url}negative"

                run

                expect(actual_results).to eq({
                    'status'  => 'not_found',
                    'message' => plugin::STATUSES[:not_found]
                })
            end
        end
    end

    context 'when the webapp behaves erratically' do
        it 'logs that the tests were inconclusive' do
            options.url = "#{url}inconclusive"

            run

            expect(actual_results).to eq({
                'status'  => 'inconclusive',
                'message' => plugin::STATUSES[:inconclusive]
            })
        end
    end
end
