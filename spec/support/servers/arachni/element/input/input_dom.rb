require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <script>
            function handleOnInput() {
                document.getElementById("container").innerHTML =
                    document.getElementById("my-input").value;
            }
        </script>

        <body>
            <input oninput="handleOnInput();" id="my-input" name="my-input" value="1" />

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/without-inputs' do
    <<-EOHTML
    <html>
        <body>
            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/input/type/text/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input type="text" id="my-input" value="stuff">

            <div id="container">
            </div>

            <script>
               document.getElementById('my-input').addEventListener('input', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end

get '/input/type/none/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" value="stuff">

            <div id="container">
            </div>

            <script>
               document.getElementById('my-input').addEventListener('input', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end

get '/textarea/with_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text">stuff</textarea>

            <div id="container">
            </div>

            <script>
               document.getElementById('my-input').addEventListener('input', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end

get '/without_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text" value="stuff">stuff</textarea>
        </body>
    </html>
    EOHTML
end
