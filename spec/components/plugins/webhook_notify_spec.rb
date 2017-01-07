require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    context 'when the content-type is JSON' do
        it 'sends a POST request at the end of the scan' do
            options.plugins['webhook_notify'] = {
                'url'          => "#{options.url}/hook",
                'content_type' => 'json',
                'payload'      => {
                    'SEED'          => '$SEED$',
                    'URL'           => '$URL$',
                    'MAX_SEVERITY'  => '$MAX_SEVERITY$',
                    'ISSUE_COUNT'   => '$ISSUE_COUNT$',
                    'DURATION'      => '$DURATION$'
                }.to_json
            }

            run

            expect(actual_results['success']).to eq true
            expect(actual_results['status']).to eq 'ok'
            expect(actual_results['message']).to eq 'No error'
            expect(actual_results['response']).to eq(
                "HTTP/1.1 200 OK\r\n" <<
                "Content-Type: text/html;charset=utf-8\r\n" <<
                "X-XSS-Protection: 1; mode=block\r\n" <<
                "X-Content-Type-Options: nosniff\r\n" <<
                "X-Frame-Options: SAMEORIGIN\r\n" <<
                "Content-Length: 174\r\n\r\n" <<
                "[\"application/json\",\"{\\\"SEED\\\":\\\"#{Arachni::Utilities.random_seed}\\\",\\\"URL\\\":\\\"#{options.url}\\\",\\\"MAX_SEVERITY\\\":\\\"\\\",\\\"ISSUE_COUNT\\\":\\\"0\\\",\\\"DURATION\\\":\\\"#{framework.report.delta_time}\\\"}\"]"
            )
        end
    end

    context 'when the content-type is XML' do
        it 'sends a POST request at the end of the scan' do
            options.plugins['webhook_notify'] = {
                'url'          => "#{options.url}/hook",
                'content_type' => 'xml',
                'payload'      => '<SEED>$SEED$</SEED>' <<
                    '<URL>$URL$</URL>' <<
                    '<MAX_SEVERITY>$MAX_SEVERITY$</MAX_SEVERITY>' <<
                    '<ISSUE_COUNT>$ISSUE_COUNT$</ISSUE_COUNT>' <<
                    '<DURATION>$DURATION$</DURATION>'
            }

            run

            expect(actual_results['success']).to eq true
            expect(actual_results['status']).to eq 'ok'
            expect(actual_results['message']).to eq 'No error'
            expect(actual_results['response']).to eq(
                "HTTP/1.1 200 OK\r\n" <<
                "Content-Type: text/html;charset=utf-8\r\n" <<
                "X-XSS-Protection: 1; mode=block\r\n" <<
                "X-Content-Type-Options: nosniff\r\n" <<
                "X-Frame-Options: SAMEORIGIN\r\n" <<
                "Content-Length: 185\r\n\r\n" <<
                "[\"application/xml\",\"<SEED>#{Arachni::Utilities.random_seed}</SEED><URL>#{options.url}</URL><MAX_SEVERITY></MAX_SEVERITY><ISSUE_COUNT>0</ISSUE_COUNT><DURATION>#{framework.report.delta_time}</DURATION>\"]"
            )
        end
    end
end
