require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.url = url
    end

    def results
        {
            "#{url}" => {
                "X-Xss-Protection" => "1; mode=block",
                "X-Content-Type-Options" => "nosniff",
                "X-Frame-Options" => "SAMEORIGIN"
            },
            "#{url}1" => {
                "Weird" => "Value",
                "X-Xss-Protection" => "1; mode=block",
                "X-Content-Type-Options" => "nosniff",
                "X-Frame-Options" => "SAMEORIGIN"
            },
            "#{url}2" => {
                "Weird2" => "Value2",
                "X-Xss-Protection" => "1; mode=block",
                "X-Content-Type-Options" => "nosniff",
                "X-Frame-Options" => "SAMEORIGIN"
            }
        }

    end

    easy_test

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
