require 'sinatra'
require 'sinatra/contrib'
require_relative '../../../../../lib/arachni'

EVENTS = Arachni::Browser::Javascript::EVENTS_PER_ELEMENT[:input]

get '/' do
    html = '<html><body>'

    EVENTS.each do |event|
        html << "<a href='/#{event}'>#{event}</a>"
    end

    html << "<a href='/with_button'>With button</a>"
    html + '</body></html>'
end

EVENTS.each do |event|
    get "/#{event}" do
        <<-EOHTML
    <html>
        <script>
            function handle#{event}() {
                document.getElementById("container").innerHTML =
                    document.getElementById("my-input").value;
            }
        </script>

        <body>
            <input #{event}="handle#{event}();" id="my-input" name="my-input" />

            <div id="container">
            </div>
        </body>
    </html>
        EOHTML
    end
end

get '/with_button' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text">
            <button id="insert">Insert into DOM</button>

            <div id="container">
            </div>

            <script>
               document.getElementById('insert').addEventListener('click', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end
