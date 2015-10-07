require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.url = url
    end

    context 'when no patterns are given' do
        it 'logs all headers' do
            run

            expect(actual_results).to eq({
                url => {
                    "Content-Type" => "text/html;charset=utf-8",
                    "X-Xss-Protection" => "1; mode=block",
                    "X-Content-Type-Options" => "nosniff",
                    "X-Frame-Options" => "SAMEORIGIN",
                    "Content-Length" => "54"
                },
                "#{url}1" => {
                    "Content-Type" => "text/html;charset=utf-8",
                    "Weird" => "Value",
                    "X-Xss-Protection" => "1; mode=block",
                    "X-Content-Type-Options" => "nosniff",
                    "X-Frame-Options" => "SAMEORIGIN",
                    "Content-Length" => "5"
                },
                "#{url}2" => {
                    "Content-Type" => "text/html;charset=utf-8",
                    "Weird2" => "Value2",
                    "X-Xss-Protection" => "1; mode=block",
                    "X-Content-Type-Options" => "nosniff",
                    "X-Frame-Options" => "SAMEORIGIN",
                    "Content-Length" => "6"
                }
            })
        end
    end

    context 'when :include patterns are given' do
        it 'only logs headers whose name matches the pattern' do
            options.plugins[name_from_filename] = {
                'include' => 'weird|frame'
            }

            run

            expect(actual_results).to eq({
                url => {
                    "X-Frame-Options" => "SAMEORIGIN"
                },
                "#{url}1" => {
                    "Weird" => "Value",
                    "X-Frame-Options" => "SAMEORIGIN"
                },
                "#{url}2" => {
                    "Weird2" => "Value2",
                    "X-Frame-Options" => "SAMEORIGIN"
                }
            })
        end
    end

    context 'when :exclude patterns are given' do
        it 'only logs headers whose name matches the pattern' do
            options.plugins[name_from_filename] = {
                'exclude' => 'weird|frame'
            }

            run

            expect(actual_results).to eq({
                url => {
                    "Content-Type" => "text/html;charset=utf-8",
                    "X-Xss-Protection" => "1; mode=block",
                    "X-Content-Type-Options" => "nosniff",
                    "Content-Length" => "54"
                },
                "#{url}1" => {
                    "Content-Type" => "text/html;charset=utf-8",
                    "X-Xss-Protection" => "1; mode=block",
                    "X-Content-Type-Options" => "nosniff",
                    "Content-Length" => "5"
                },
                "#{url}2" => {
                    "Content-Type" => "text/html;charset=utf-8",
                    "X-Xss-Protection" => "1; mode=block",
                    "X-Content-Type-Options" => "nosniff",
                    "Content-Length" => "6"
                }
            })
        end
    end

    describe '.merge' do
        it 'merges the results of different instances' do
            results = [
                {
                    "#{url}" => {
                        'Name' => 'Value'
                    },
                },
                {
                    "#{url}" => {
                        'Name2' => 'Value2'
                    },
                    "#{url}2" => {
                        'Name22' => 'Value22'
                    },
                },
            ]

            expect(framework.plugins[component_name].merge( results )).to eq({
                "#{url}" => {
                    "Name" => "Value",
                    "Name2" => "Value2"
                },
                "#{url}2" => {
                    "Name22" => "Value22"
                }
            })
        end
    end
end
