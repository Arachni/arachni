=begin
    Copyright 2018 Adam Torok <adam.torok96@gmail.com>
=end

require 'net/http'

# @author Adam Torok <adam.torok96@gmail.com>
class Arachni::Plugins::SlackNotify < Arachni::Plugin::Base

  TRIES = 5

  def run
    wait_while_framework_running
  end

  def clean_up
    report = framework.report

    attachments = []
    attachments[0] = {
        text: "Found #{report.issues.size} unique issues."
    }

    uri = URI(options[:webhook_url])

    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = {
        text: "Scan for #{framework.options.url} finished in #{report.delta_time}",
        attachments: attachments
    }.to_json

    print_status 'Sending the notification...'

    sent      = false
    exception = nil

    TRIES.times do |i|
      begin
        Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(req)
        end

        sent = true
        break
      rescue => e
        exception = e
        print_bad "Attempt ##{i} failed, retrying..."
      end
    end

    if sent
      print_status 'Done.'
    else
      print_error "Failed after #{TRIES} tries."
      print_exception exception
    end
  end

  def self.info
    {
        name:        'Slack notify',
        description: %q{Sends a Slack notification over HTTP(S) at the end of the scan.},
        author:      'Adam Torok <adam.torok96@gmail.com>',
        version:     '0.1.0',
        options:     [
            Options::String.new( :webhook_url,
                                 required:    true,
                                 description: 'Slack Webhook url'
            )
        ]
    }
  end

end
