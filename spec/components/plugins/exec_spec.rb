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
        pre.delete('runtime').should be_kind_of Float
        pre.delete('pid').should be_kind_of Integer

        pre.should == {
            "status"     => 0,
            "executable" => "echo \"#{options.url} #{scheme} #{host} #{port} pre 0 0 preparing\"",
            "stdout"     => "#{options.url} #{scheme} #{host} #{port} pre 0 0 preparing\n",
            "stderr"     => ""
        }

        during = actual_results['during']
        during.delete('runtime').should be_kind_of Float
        during.delete('pid').should be_kind_of Integer

        during.should == {
            "status"     => 0,
            "executable" => "echo \"#{options.url} #{scheme} #{host} #{port} during 0 0 preparing\"",
            "stdout"     => "#{options.url} #{scheme} #{host} #{port} during 0 0 preparing\n",
            "stderr"     => ""
        }

        post = actual_results['post']
        post.delete('runtime').should be_kind_of Float
        post.delete('pid').should be_kind_of Integer

        post.should == {
            "status"     => 0,
            "executable" => "echo \"#{options.url} #{scheme} #{host} #{port} post 0 2 cleanup\"",
            "stdout"     => "#{options.url} #{scheme} #{host} #{port} post 0 2 cleanup\n",
            "stderr"     => ""
        }
    end
end
