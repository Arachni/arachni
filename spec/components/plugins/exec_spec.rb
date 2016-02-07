require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    it 'executes a Ruby script under the scope of the running plugin' do
        options.url = web_server_url_for(:framework)

        cmd = 'echo "__URL__ __URL_SCHEME__ __URL_HOST__ __URL_PORT__ __STAGE__ __ISSUE_COUNT__ __SITEMAP_SIZE__ __FRAMEWORK_STATUS__"'
        options.plugins[component_name] = {
            'pre'    => cmd,
            'during' => cmd,
            'post'   => cmd
        }

        run

        parsed_url = Arachni::URI( options.url )
        scheme = parsed_url.scheme
        host   = parsed_url.host
        port   = parsed_url.port

        pre = actual_results['pre']
        expect(pre.delete('runtime')).to be_kind_of Float
        expect(pre.delete('pid')).to be_kind_of Integer

        expect(pre).to eq({
            "status"     => 0,
            "executable" => "echo \"#{options.url} #{scheme} #{host} #{port} pre 0 0 preparing\"",
            "stdout"     => "#{options.url} #{scheme} #{host} #{port} pre 0 0 preparing\n",
            "stderr"     => ""
        })

        during = actual_results['during']
        expect(during.delete('runtime')).to be_kind_of Float
        expect(during.delete('pid')).to be_kind_of Integer

        expect(during).to eq({
            "status"     => 0,
            "executable" => "echo \"#{options.url} #{scheme} #{host} #{port} during 0 0 scanning\"",
            "stdout"     => "#{options.url} #{scheme} #{host} #{port} during 0 0 scanning\n",
            "stderr"     => ""
        })

        post = actual_results['post']
        expect(post.delete('runtime')).to be_kind_of Float
        expect(post.delete('pid')).to be_kind_of Integer

        expect(post).to eq({
            "status"     => 0,
            "executable" => "echo \"#{options.url} #{scheme} #{host} #{port} post 0 2 cleanup\"",
            "stdout"     => "#{options.url} #{scheme} #{host} #{port} post 0 2 cleanup\n",
            "stderr"     => ""
        })
    end
end
